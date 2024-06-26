# terraform-azurerm-avm-ptn-network-routeserver

This is the route server pattern module for the Azure Verified Modules library.  This module deploys a virtual network based route server along with common associated resources.  It leverages both the AzureRM and AzAPI providers and sets a number of initial defaults to minimize the overall inputs for simple configurations. 

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **WILL NOT** be published at version `1.0.0` or higher at this time.
> 
> However, it is important to note that this **DOES NOT** mean that this module cannot be consumed and utilized. It **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat this just like any other IaC module and raise issues or feature requests against it as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.
