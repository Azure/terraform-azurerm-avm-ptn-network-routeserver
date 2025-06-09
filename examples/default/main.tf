## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.5.2"
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
  version = "0.8.1"

  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  name                = module.naming.virtual_network.name_unique
  subnets = {
    "GatewaySubnet" = {
      name             = "GatewaySubnet"
      address_prefixes = ["10.0.0.0/24"]
    }
    "RouteServerSubnet" = {
      name             = "RouteServerSubnet"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}

module "default" {
  source = "../.."

  location                        = azurerm_resource_group.this.location
  name                            = "${module.naming.virtual_wan.name_unique}-rs"
  resource_group_name             = azurerm_resource_group.this.name
  resource_group_resource_id      = azurerm_resource_group.this.id
  route_server_subnet_resource_id = module.virtual_network.subnets["RouteServerSubnet"].id
  enable_branch_to_branch         = true
  enable_telemetry                = var.enable_telemetry
  private_ip_allocation_method    = "Dynamic"
  routeserver_public_ip_config = {
    name = "routeserver-pip"
  }
}

