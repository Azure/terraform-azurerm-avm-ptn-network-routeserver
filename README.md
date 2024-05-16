<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-ptn-network-routeserver

This is the route server pattern module for the Azure Verified Modules library.  This module deploys a virtual network based route server along with common associated resources.  It leverages both the AzureRM and AzAPI providers and sets a number of initial defaults to minimize the overall inputs for simple configurations.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **WILL NOT** be published at version `1.0.0` or higher at this time.
>
> However, it is important to note that this **DOES NOT** mean that this module cannot be consumed and utilized. It **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat this just like any other IaC module and raise issues or feature requests against it as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 1.13, != 1.13.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.10)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.74)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.10)

## Resources

The following resources are used by this module:

- [azapi_resource.route_server_hub](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.route_server_ip_config_dynamic](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_public_ip.route_server_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_virtual_hub_bgp_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_bgp_connection) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)
- [time_sleep.wait_300_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azurerm_virtual_hub.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_hub) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this route server resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_resource_group_resource_id"></a> [resource\_group\_resource\_id](#input\_resource\_group\_resource\_id)

Description: The Azure Resource ID for the resource group where the resources will be deployed.

Type: `string`

### <a name="input_route_server_subnet_resource_id"></a> [route\_server\_subnet\_resource\_id](#input\_route\_server\_subnet\_resource\_id)

Description: The Azure resource ID for the route server subnet where this route server resource will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_bgp_connections"></a> [bgp\_connections](#input\_bgp\_connections)

Description: A map of bgp connections to make on each route server."
- `<map key>` - An arbitrary map key to differentiate each instance of the map.
  - `name` - (Required) - The name to use for the bgp connection
  - `peer_asn` - (Required) - The ASN for the peer NVA
  - `peer_ip` - (Required) - The IP address for the peer NVA

Type:

```hcl
map(object({
    name     = string
    peer_asn = string
    peer_ip  = string
  }))
```

Default: `{}`

### <a name="input_enable_branch_to_branch"></a> [enable\_branch\_to\_branch](#input\_enable\_branch\_to\_branch)

Description: Should the branch to branch feature be enabled. Defaults to false.

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_hub_routing_preference"></a> [hub\_routing\_preference](#input\_hub\_routing\_preference)

Description: The routing preference for this route server.  Valid values are `ASPath`, `ExpressRoute`, or `VpnGateway`. Defaults to `ExpressRoute`

Type: `string`

Default: `"ExpressRoute"`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address)

Description: The private ip address to use for the route server IP\_configuration if the `private_ip_allocation_method` is set to `Static`.

Type: `string`

Default: `null`

### <a name="input_private_ip_allocation_method"></a> [private\_ip\_allocation\_method](#input\_private\_ip\_allocation\_method)

Description: The private IP Address allocation method for this route server. Valid values are `Static` or `Dynamic`. Defaults to `Dynamic`.

Type: `string`

Default: `"Dynamic"`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_routeserver_public_ip_name"></a> [routeserver\_public\_ip\_name](#input\_routeserver\_public\_ip\_name)

Description: The name for the public ip address resource associated with the route server.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) - The map of tags to be applied to the resource

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: This is the full output for the resource. It contains the following properties:

- `id` - type: string - The Azure Resource ID of the virtual hub resource that this route server is associated to.
- `location` - type: string - The azure location of the route server resource.
- `name` - type: string - The name of the route server resource.
- `tags' - type: map(string) - A tags map for any directly assigned tags for the route server resource.
- 'virtual_router_asn` - type: number - The ASN number for the route server resource.
- `virtual_router_ips` - type: list(string) - A list containing the peer ip's for route server.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: n/a

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->