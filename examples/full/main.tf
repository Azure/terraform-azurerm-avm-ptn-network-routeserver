terraform {
  required_version = "~> 1.6"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13, != 1.13.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

data "template_file" "node_config" {
  template = file("${path.module}/ios_config_template.txt")
  vars = {
    nic_0_ip_address = "10.0.2.5"
    nic_0_netmask    = cidrnetmask(module.virtual_network.subnets["NVASubnet"].address_prefixes[0])
    asn              = "65111"
    router_id        = "65.1.1.1"
    avs_ars_ip_0     = module.full_route_server.resource.virtual_router_ips[0]
    avs_ars_ip_1     = module.full_route_server.resource.virtual_router_ips[1]
  }
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.1.4"

  name                          = module.naming.virtual_network.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  virtual_network_address_space = ["10.0.0.0/16"]

  subnets = {
    "GatewaySubnet" = {
      address_prefixes = ["10.0.0.0/24"]
    }
    "RouteServerSubnet" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "NVASubnet" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = ">= 0.5.0"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  tags = {
    "scenario" = "AVM full route server"
  }
}

#Agree to the marketplace offering if it hasn't been already
locals {
  offer     = "cisco-c8000v-byol"
  plan      = "17_12_02-byol"
  publisher = "cisco"
}

data "azurerm_subscription" "current" {}

data "azapi_resource_action" "plans" {
  type                   = "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements@2021-01-01"
  method                 = "GET"
  resource_id            = "${data.azurerm_subscription.current.id}/providers/Microsoft.MarketplaceOrdering/offerTypes/virtualmachine/publishers/${local.publisher}/offers/${local.offer}/plans/${local.plan}/agreements/current"
  response_export_values = ["*"]
}

resource "azurerm_marketplace_agreement" "cisco" {
  count = data.azapi_resource_action.plans.output.properties.accepted == true ? 0 : 1

  offer     = local.offer
  plan      = local.plan
  publisher = local.publisher
}

#create a cisco 8k nva for demonstrating bgp peers
module "cisco_8k" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.13.0"

  admin_credential_key_vault_resource_id = module.avm_res_keyvault_vault.resource.id
  admin_username                         = "azureuser"
  disable_password_authentication        = false
  enable_telemetry                       = var.enable_telemetry
  encryption_at_host_enabled             = true
  generate_admin_password_or_ssh_key     = true
  name                                   = module.naming.virtual_machine.name_unique
  resource_group_name                    = azurerm_resource_group.this.name
  location                               = azurerm_resource_group.this.location
  virtualmachine_os_type                 = "Linux"
  virtualmachine_sku_size                = "Standard_F4s_v2"
  zone                                   = "1"
  custom_data                            = base64encode(data.template_file.node_config.rendered)

  network_interfaces = {
    network_interface_0 = {
      name                           = "${module.naming.virtual_machine.name_unique}-nic_0"
      accelerated_networking_enabled = true
      ip_forwarding_enabled          = true
      ip_configurations = {
        ip_configuration_cp_facing = {
          name                          = "${module.naming.virtual_machine.name_unique}-internal"
          private_ip_address            = "10.0.2.5"
          private_ip_address_version    = "IPv4"
          private_ip_address_allocation = "Static"
          private_ip_subnet_resource_id = module.virtual_network.subnets["NVASubnet"].id
          is_primary_ipconfiguration    = true
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 16
  }

  plan = {
    name      = local.plan
    product   = local.offer
    publisher = local.publisher

  }

  source_image_reference = {
    publisher = local.publisher
    offer     = local.offer
    sku       = local.plan
    version   = "latest"
  }

  tags = {
    "scenario" = "AVM full route server"
  }

  depends_on = [
    module.avm_res_keyvault_vault, azurerm_marketplace_agreement.cisco
  ]
}

data "azurerm_client_config" "current" {}

module "full_route_server" {
  source = "../.."
  # source             = "Azure/avm-res-network-routeserver/azurerm"
  # version            = "0.1.1"

  enable_branch_to_branch         = true
  enable_telemetry                = var.enable_telemetry
  hub_routing_preference          = "ASPath"
  location                        = azurerm_resource_group.this.location
  name                            = "${module.naming.virtual_wan.name_unique}-rs"
  private_ip_allocation_method    = "Static"
  private_ip_address              = "10.0.1.10"
  resource_group_name             = azurerm_resource_group.this.name
  resource_group_resource_id      = azurerm_resource_group.this.id
  route_server_subnet_resource_id = module.virtual_network.subnets["RouteServerSubnet"].id

  bgp_connections = {
    cisco_8k = {
      name     = module.cisco_8k.virtual_machine.name
      peer_asn = "65111"
      peer_ip  = "10.0.2.5"
    }
  }

  routeserver_public_ip_config = {
    name              = "routeserver-pip"
    allocation_method = "Static"
    ip_version        = "IPv4"
    sku               = "Standard"
    sku_tier          = "Regional"
    zones             = ["1", "2", "3"]
  }


  /* add a lock if desired - leaving out so tests will run cleanly
  lock = {
    kind = "CanNotDelete"
    name = "example-delete-lock"
  }
  */

  role_assignments = {
    role_assignment_1 = {
      principal_id               = data.azurerm_client_config.current.object_id
      role_definition_id_or_name = "Contributor"
      description                = "Assign the Contributor role to the deployment user on this route server resource scope."
    }
  }

  tags = {
    "scenario" = "AVM full route server"
  }
}

output "resource_output" {
  value = module.full_route_server.resource
}
