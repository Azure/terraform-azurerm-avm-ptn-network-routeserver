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
DESCRIPTION  
  nullable    = false
}

variable "routeserver_public_ip_name" {
  type        = string
  default     = null
  description = "The name for the public ip address resource associated with the route server."
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) - The map of tags to be applied to the resource"
}
