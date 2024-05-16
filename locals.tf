locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  routeserver_public_ip_name         = coalesce(var.routeserver_public_ip_name, "${var.name}-pip")
}


