resource "azapi_resource" "route_server_hub" {
  type = "Microsoft.Network/virtualHubs@2023-04-01"
  body = {
    properties = {
      sku                        = "Standard"
      hubRoutingPreference       = var.hub_routing_preference
      allowBranchToBranchTraffic = var.enable_branch_to_branch
    }
  }
  location                  = var.location
  name                      = var.name
  parent_id                 = var.resource_group_resource_id
  response_export_values    = ["*"]
  schema_validation_enabled = false
}

resource "azurerm_public_ip" "route_server_pip" {
  allocation_method       = var.routeserver_public_ip_config.allocation_method
  location                = coalesce(var.routeserver_public_ip_config.location, var.location)
  name                    = coalesce(var.routeserver_public_ip_config.name, "${var.name}-pip")
  resource_group_name     = coalesce(var.routeserver_public_ip_config.resource_group_name, var.resource_group_name)
  ddos_protection_mode    = var.routeserver_public_ip_config.ddos_protection_mode
  ddos_protection_plan_id = var.routeserver_public_ip_config.ddos_protection_plan_id
  ip_tags                 = var.routeserver_public_ip_config.ip_tags
  ip_version              = var.routeserver_public_ip_config.ip_version
  public_ip_prefix_id     = var.routeserver_public_ip_config.public_ip_prefix_resource_id
  sku                     = var.routeserver_public_ip_config.sku
  sku_tier                = var.routeserver_public_ip_config.sku_tier
  tags                    = var.routeserver_public_ip_config.tags != {} ? var.routeserver_public_ip_config.tags : var.tags
  zones                   = var.routeserver_public_ip_config.zones
}

resource "azapi_resource" "route_server_ip_config" {
  type = "Microsoft.Network/virtualHubs/ipConfigurations@2023-04-01"
  body = {
    properties = {
      subnet = {
        id = var.route_server_subnet_resource_id
      }
      PublicIPAddress = {
        id = azurerm_public_ip.route_server_pip.id
      }
      privateIPAllocationMethod = var.private_ip_allocation_method
      privateIpAddress          = (lower(var.private_ip_allocation_method) == "static" ? var.private_ip_address : null)
    }
  }
  name                      = var.name
  parent_id                 = azapi_resource.route_server_hub.id
  response_export_values    = ["*"]
  schema_validation_enabled = false
}

resource "time_sleep" "wait_300_seconds" {
  create_duration = "300s"

  depends_on = [azapi_resource.route_server_ip_config]
}

#doing a forced read of the resource as the peer ips don't populate right away 
data "azurerm_virtual_hub" "this" {
  name                = azapi_resource.route_server_hub.name
  resource_group_name = var.resource_group_name

  depends_on = [time_sleep.wait_300_seconds]
}

resource "azurerm_virtual_hub_bgp_connection" "this" {
  for_each = var.bgp_connections

  name           = each.value.name
  peer_asn       = each.value.peer_asn
  peer_ip        = each.value.peer_ip
  virtual_hub_id = azapi_resource.route_server_hub.id

  depends_on = [
    azapi_resource.route_server_ip_config
  ]
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.route_server_hub.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check

  depends_on = [
    azapi_resource.route_server_ip_config,
    azurerm_virtual_hub_bgp_connection.this
  ]
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.route_server_hub.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."

  depends_on = [
    azapi_resource.route_server_ip_config,
    azurerm_virtual_hub_bgp_connection.this
  ]
}

