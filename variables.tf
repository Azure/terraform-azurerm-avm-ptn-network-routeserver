variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this route server resource."

  validation {
    condition     = can(regex("^[-_a-z0-9]{1,80}$", var.name))
    error_message = "The name must be between 1 and 80 characters long with letters, numbers, dashes, or underscores."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  nullable    = false
}

variable "resource_group_resource_id" {
  type        = string
  description = "The Azure Resource ID for the resource group where the resources will be deployed."
  nullable    = false
}

variable "route_server_subnet_resource_id" {
  type        = string
  description = "The Azure resource ID for the route server subnet where this route server resource will be deployed."
  nullable    = false
}

variable "bgp_connections" {
  type = map(object({
    name     = string
    peer_asn = string
    peer_ip  = string
  }))
  default     = {}
  description = <<DESCRIPTION
A map of bgp connections to make on each route server."

- `<map key>` - An arbitrary map key to differentiate each instance of the map.
  - `name` - (Required) - The name to use for the bgp connection
  - `peer_asn` - (Required) - The ASN for the peer NVA
  - `peer_ip` - (Required) - The IP address for the peer NVA

Example Input:
```hcl
bgp_connections = {
  cisco_8k = {
    name     = module.cisco_8k.virtual_machine.name
    peer_asn = "65111"
    peer_ip  = "10.0.2.5"
  }
}
```
DESCRIPTION
  nullable    = false
}

variable "enable_branch_to_branch" {
  type        = bool
  default     = false
  description = "Should the branch to branch feature be enabled. Defaults to false."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "hub_routing_preference" {
  type        = string
  default     = "ExpressRoute"
  description = "The routing preference for this route server.  Valid values are `ASPath`, `ExpressRoute`, or `VpnGateway`. Defaults to `ExpressRoute`"
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Example Input:
```hcl
lock = {
  kind = "CanNotDelete"
  name = "example-delete-lock"
}
```
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "private_ip_address" {
  type        = string
  default     = null
  description = "The private ip address to use for the route server IP_configuration if the `private_ip_allocation_method` is set to `Static`."
}

variable "private_ip_allocation_method" {
  type        = string
  default     = "Dynamic"
  description = "The private IP Address allocation method for this route server. Valid values are `Static` or `Dynamic`. Defaults to `Dynamic`."
}

# tflint-ignore: terraform_unused_declarations
variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Example Input
```hcl
role_assignments = {
  role_assignment_1 = {
    principal_id               = data.azurerm_client_config.current.object_id
    role_definition_id_or_name = "Contributor"
    description                = "Assign the Contributor role to the deployment user on this route server resource scope."
  }
}
```
DESCRIPTION  
  nullable    = false
}

variable "routeserver_public_ip_config" {
  type = object({
    allocation_method                = optional(string, "Static")
    ddos_protection_mode             = optional(string, "VirtualNetworkInherited")
    ddos_protection_plan_resource_id = optional(string, null)
    ip_tags                          = optional(map(string), {})
    ip_version                       = optional(string, "IPv4")
    location                         = optional(string, null)
    name                             = optional(string, null)
    public_ip_prefix_resource_id     = optional(string, null)
    resource_group_name              = optional(string, null)
    sku                              = optional(string, "Standard")
    sku_tier                         = optional(string, "Regional")
    tags                             = optional(map(string), {})
    zones                            = optional(list(string), ["1", "2", "3"])
  })
  default = {
    allocation_method    = "Static"
    ddos_protection_mode = "VirtualNetworkInherited"
    ip_version           = "IPv4"
    sku_tier             = "Regional"
    sku                  = "Standard"
    zones                = ["1", "2", "3"]
  }
  description = <<DESCRIPTION
This object provides overrides for the routeserver's public IP. The defaults are the general best practice, but in rare cases it is necessary to override one or more of these defaults and this input provides that option.

- `allocation_method`           = (Required) - Defines the allocation method for this IP address. Possible values are Static or Dynamic.
- `ddos_protection_mode`        = (Optional) - The DDoS protection mode of the public IP. Possible values are Disabled, Enabled, and VirtualNetworkInherited. Defaults to VirtualNetworkInherited.
- `ddos_protection_plan_resource_id`     = (Optional) - The ID of DDoS protection plan associated with the public IP. ddos_protection_plan_resource_id can only be set when ddos_protection_mode is Enabled
- `idle_timeout_in_minutes`     = (Optional) - Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.
- `ip_tags`                     = (Optional) - A map of strings for ip tags associated with the routeserver public IP.
- `ip_version`                  = (Optional) - The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Only static IP address allocation is supported for IPv6.
- `location`                    = (Optional) - The location to deploy the public IP resource into.  Defaults to the resource group location.
- `name`                        = (Optional) - The name to use for the route Server's public IP. Defaults to the route server `name` with `-pip` appended if no value is provided.
- `public_ip_prefix_resource_id = (Optional) - The Azure resource ID of the public IP prefix to use for allocation the public IP address from when using a public IP prefix.
- `resource_group_name`         = (Optional) - The resource group name to use if deploying the routeserver public IP into a different resource group than the route server
- `sku`                         = (Optional) - The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Standard to support zones by default. Changing this forces a new resource to be created. When sku_tier is set to Global, sku must be set to Standard.
- `sku_tier`                    = (Optional) - The SKU tier of the Public IP. Accepted values are Global and Regional. Defaults to Regional
- `tags`                        = (Optional) - A mapping of tags to assign to this resource. Defaults to the module level tags variable configuration if undefined.
- `zones`                       = (Optional) - The zones configuration to use for the route server public IP.  Defaults to a zonal configuration using all three zones. Modify this value if deploying into a region that doesn't support multiple zones.

Example Input:
```hcl
routeserver_public_ip_config = {
  name              = "routeserver-pip"
  allocation_method = "Static"
  ip_version        = "IPv4"
  sku               = "Standard"
  sku_tier          = "Regional"
  zones             = ["1", "2", "3"]
}
```
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) - The map of tags to be applied to the resource"
}
