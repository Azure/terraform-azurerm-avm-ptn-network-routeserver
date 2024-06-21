terraform {
  required_version = "~> 1.6"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13, != 1.13.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.108"
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

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
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
  }
}

module "default" {
  source = "../.."
  # source             = "Azure/avm-res-network-routeserver/azurerm"
  # version            = "0.1.2"

  location                        = azurerm_resource_group.this.location
  name                            = "${module.naming.virtual_wan.name_unique}-rs"
  resource_group_name             = azurerm_resource_group.this.name
  resource_group_resource_id      = azurerm_resource_group.this.id
  private_ip_allocation_method    = "Dynamic"
  route_server_subnet_resource_id = module.virtual_network.subnets["RouteServerSubnet"].id
  enable_branch_to_branch         = true

  routeserver_public_ip_config = {
    name = "routeserver-pip"
  }

  enable_telemetry = var.enable_telemetry
}

output "resource_output" {
  value = module.default.resource
}
