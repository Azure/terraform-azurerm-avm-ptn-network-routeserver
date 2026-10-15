mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualHubs/test-route-server"
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}

mock_provider "time" {}

variables {
  location                        = "eastus2"
  name                            = "test-route-server"
  resource_group_name             = "test-rg"
  resource_group_resource_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg"
  route_server_subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/RouteServerSubnet"
  enable_telemetry                = false
}

run "supplied_tags_reach_hub" {
  command = plan

  variables {
    tags = {
      environment = "test"
      owner       = "network"
    }
  }

  assert {
    condition     = azapi_resource.route_server_hub.tags == tomap({ environment = "test", owner = "network" })
    error_message = "The route server hub must receive the caller's complete tag map."
  }
}

run "empty_tags_remain_empty" {
  command = plan

  variables {
    tags = {}
  }

  assert {
    condition     = azapi_resource.route_server_hub.tags == var.tags && length(azapi_resource.route_server_hub.tags) == 0
    error_message = "An empty tag map must remain empty on the route server hub."
  }
}
