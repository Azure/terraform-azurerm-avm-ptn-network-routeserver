<!-- BEGIN_TF_DOCS -->
# Full virtual network route server example

This example demonstrates each feature of the module.  It includes the follow features:
- Enables branch-to-branch
- Sets the preferred routing to ASPath instead of ExpressRoute Gateway
- Configures a static private IP configuration
- Creates tags
- Creates a role assignment assigning the deployment user Contributor access on the resource
- Creates a BYOL Cisco 8k network virtual appliance virtual machine with a very basic configuration
- Creates a BGP connection between the route server and the NVA virtual machine

```hcl
## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.7"
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
  version = "~> 0.4"
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
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.7.1"

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
    create = "90s"
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
  count = jsondecode(data.azapi_resource_action.plans.output).properties.accepted == true ? 0 : 1

  offer     = local.offer
  plan      = local.plan
  publisher = local.publisher
}

#create a cisco 8k nva for demonstrating bgp peers
module "cisco_8k" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.15.0"

  admin_username                     = "azureuser"
  disable_password_authentication    = false
  enable_telemetry                   = var.enable_telemetry
  encryption_at_host_enabled         = true
  generate_admin_password_or_ssh_key = true
  name                               = module.naming.virtual_machine.name_unique
  resource_group_name                = azurerm_resource_group.this.name
  location                           = azurerm_resource_group.this.location
  os_type                            = "Linux"
  sku_size                           = "Standard_F4s_v2"
  zone                               = "1"
  custom_data                        = base64encode(data.template_file.node_config.rendered)

  generated_secrets_key_vault_secret_config = {
    name                  = "${module.naming.virtual_machine.name_unique}-password"
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
  }

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
  # version            = "0.1.2"

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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13, != 1.13.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.108)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_template"></a> [template](#requirement\_template) (~> 2.2)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.108)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

- <a name="provider_template"></a> [template](#provider\_template) (~> 2.2)

## Resources

The following resources are used by this module:

- [azurerm_marketplace_agreement.cisco](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azapi_resource_action.plans](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_action) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) (data source)
- [template_file.node_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

The following outputs are exported:

### <a name="output_resource_output"></a> [resource\_output](#output\_resource\_output)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.7.1

### <a name="module_cisco_8k"></a> [cisco\_8k](#module\_cisco\_8k)

Source: Azure/avm-res-compute-virtualmachine/azurerm

Version: 0.15.0

### <a name="module_full_route_server"></a> [full\_route\_server](#module\_full\_route\_server)

Source: ../..

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.4

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.7

### <a name="module_virtual_network"></a> [virtual\_network](#module\_virtual\_network)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: 0.1.4

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->