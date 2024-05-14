output "resource" {
  description = <<DESCRIPTION
This is the full output for the resource. It contains the following properties:

- `id` - type: string - The Azure Resource ID of the virtual hub resource that this route server is associated to.
- `location` - type: string - The azure location of the route server resource.
- `name` - type: string - The name of the route server resource.
- `tags' - type: map(string) - A tags map for any directly assigned tags for the route server resource.
- 'virtual_router_asn` - type: number - The ASN number for the route server resource. 
- `virtual_router_ips` - type: list(string) - A list containing the peer ip's for route server.
DESCRIPTION
  value       = data.azurerm_virtual_hub.this
}
