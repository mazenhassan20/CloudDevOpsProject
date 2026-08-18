resource "azurerm_resource_group" "rg" {
  name     = "ivolve-project-rg"
  location = "switzerlandnorth"
}

module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  prefix              = "ivolve"
}

module "acr" {
  source              = "./modules/acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  acr_name            = "ivolveacrproj123" 
}

module "aks" {
  source              = "./modules/aks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  prefix              = "ivolve"
  subnet_id           = module.network.aks_subnet_id
  acr_id              = module.acr.acr_id
}
