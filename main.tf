terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "shriram-poc"
    storage_account_name = "shriramtfpoc"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "052c9332-2138-411f-adef-e7445d02ecc6"
}

#local variables
locals {
  resource_group_name     = "shriram-poc"
  resource_group_location = "Central India"
  virtual_network_name    = "Vnet-NTS-SUPERAPP-ShriramONE"
  subnet_name             = "subnet-aks-ci-prod-shriramone"
  aks_cluster_name        = "aks_shriramone_prod"
  vm_size_systempool      = "Standard_D2_v3"
  vm_size_userpool        = "Standard_D8s_v5"
}

# reading resource group
resource "azurerm_resource_group" "prod_rg" {
  name     = local.resource_group_name
  location = local.resource_group_location
}

# reading virtual network
# data "azurerm_virtual_network" "vnet-prod" {
#   name                = local.virtual_network_name
#   resource_group_name = data.azurerm_resource_group.prod_rg.name
# }

# # reading subnet
# data "azurerm_subnet" "aks_subnet_prod" {
#   name                 = local.subnet_name
#   virtual_network_name = data.azurerm_virtual_network.vnet-prod.name
#   resource_group_name  = data.azurerm_resource_group.prod_rg.name
# }

# resource "azurerm_route_table" "rt_prod" {
#   name                = "rt-${local.Environment}"
#   location            = var.prod_rg_location
#   resource_group_name = data.azurerm_resource_group.prod_rg.name
# }

# resource "azurerm_subnet_route_table_association" "rt_subnet_prod" {
#   subnet_id      = data.azurerm_subnet.aks_subnet_prod.id
#   route_table_id = azurerm_route_table.rt_prod.id
# }

# creation of AKS private cluster
resource "azurerm_kubernetes_cluster" "prod_aks" {
  name                    = local.aks_cluster_name
  location                = var.prod_rg_location
  resource_group_name     = azurerm_resource_group.prod_rg.name
  private_cluster_enabled = true
  dns_prefix              = "aksprod"


  default_node_pool {
    name       = "systempool"
    node_count = 1
    vm_size    = local.vm_size_systempool
    # vnet_subnet_id = data.azurerm_subnet.aks_subnet_prod.id
    node_labels = {
      "type" = "system"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    outbound_type  = "userDefinedRouting"
  }
  #  depends_on = [
  #     azurerm_route.rt_prod
  #   ]
  tags = {
    Environment = var.Environment
  }
  # depends_on = [
  #   "DC-ShriramONE-C-IND"
  # ]
}


# adding nodepool
resource "azurerm_kubernetes_cluster_node_pool" "prod_userpool01" {
  name                  = "apppool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.prod_aks.id
  vm_size               = local.vm_size_userpool
  node_count            = 1
  enable_auto_scaling   = true
  max_count             = 6
  node_labels = {
    type = "application"
  }

  tags = {
    Environment = var.Environment
  }
}

# adding additional nodepool
resource "azurerm_kubernetes_cluster_node_pool" "prod_userpool02" {
  name                  = "rabbitmqpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.prod_aks.id
  vm_size               = local.vm_size_userpool
  node_count            = 1
  enable_auto_scaling   = true
  max_count             = 2
  node_labels = {
    type = "rabbitmq"
  }

  # depends_on = [
  #   azurerm_resource_group.shriram_prod
  # ]

  tags = {
    Environment = var.Environment
  }
}



