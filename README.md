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

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.108)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.10)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 1.13, != 1.13.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.108)

- <a name="provider_modtm"></a> [modtm](#provider\_modtm) (~> 0.3)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.10)

## Resources

The following resources are used by this module:

- [azapi_resource.route_server_hub](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.route_server_ip_config](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_public_ip.route_server_pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_virtual_hub_bgp_connection.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_hub_bgp_connection) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [time_sleep.wait_300_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_virtual_hub.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_hub) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

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

Example Input:
```hcl
lock = {
  kind = "CanNotDelete"
  name = "example-delete-lock"
}
```

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

### <a name="input_routeserver_public_ip_config"></a> [routeserver\_public\_ip\_config](#input\_routeserver\_public\_ip\_config)

Description: This object provides overrides for the routeserver's public IP. The defaults are the general best practice, but in rare cases it is necessary to override one or more of these defaults and this input provides that option.

- `allocation_method`           = (Required) - Defines the allocation method for this IP address. Possible values are Static or Dynamic.
- `ddos_protection_mode`        = (Optional) - The DDoS protection mode of the public IP. Possible values are Disabled, Enabled, and VirtualNetworkInherited. Defaults to VirtualNetworkInherited.
- `ddos_protection_plan_resource_id`     = (Optional) - The ID of DDoS protection plan associated with the public IP. ddos\_protection\_plan\_resource\_id can only be set when ddos\_protection\_mode is Enabled
- `idle_timeout_in_minutes`     = (Optional) - Specifies the timeout for the TCP idle connection. The value can be set between 4 and 30 minutes.
- `ip_tags`                     = (Optional) - A map of strings for ip tags associated with the routeserver public IP.
- `ip_version`                  = (Optional) - The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Only static IP address allocation is supported for IPv6.
- `location`                    = (Optional) - The location to deploy the public IP resource into.  Defaults to the resource group location.
- `name`                        = (Optional) - The name to use for the route Server's public IP. Defaults to the route server `name` with `-pip` appended if no value is provided.
- `public_ip_prefix_resource_id = (Optional) - The Azure resource ID of the public IP prefix to use for allocation the public IP address from when using a public IP prefix.
- `resource\_group\_name`         = (Optional) - The resource group name to use if deploying the routeserver public IP into a different resource group than the route server
- `sku`                         = (Optional) - The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Standard to support zones by default. Changing this forces a new resource to be created. When sku_tier is set to Global, sku must be set to Standard.
- `sku\_tier`                    = (Optional) - The SKU tier of the Public IP. Accepted values are Global and Regional. Defaults to Regional
- `tags`                        = (Optional) - A mapping of tags to assign to this resource. Defaults to the module level tags variable configuration if undefined.
- `zones`                       = (Optional) - The zones configuration to use for the route server public IP.  Defaults to a zonal configuration using all three zones. Modify this value if deploying into a region that doesn't support multiple zones.

Example Input:
````hcl
routeserver_public_ip_config = {
  name              = "routeserver-pip"
  allocation_method = "Static"
  ip_version        = "IPv4"
  sku               = "Standard"
  sku_tier          = "Regional"
  zones             = ["1", "2", "3"]
}
```

Type:

```hcl
object({
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
```

Default:

```json
{
  "allocation_method": "Static",
  "ddos_protection_mode": "VirtualNetworkInherited",
  "ip_version": "IPv4",
  "sku": "Standard",
  "sku_tier": "Regional",
  "zones": [
    "1",
    "2",
    "3"
  ]
}
```

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

Description: The Azure Resource ID for the route server resource.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->