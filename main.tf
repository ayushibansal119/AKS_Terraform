terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.62.1"
    }
  }
}

provider "azurerm" {
  features {}

  client_id       = "246cfd43-77c5-4c63-8f77-d6a19a3876ec"
  client_secret   = "QMI8Q~tCFMcT85QTc1Kdn7hanAEj7nBCnpq3Vc7b"
  tenant_id       = "e4e34038-ea1f-4882-b6e8-ccd776459ca0"
  subscription_id = "ee22c8f0-93df-4b47-925a-d337fef522fe"
}
resource "azurerm_resource_group" "rg" {
  name     = "rg-poc-ab-dev-001"
  location = "eastus"
   tags = {
    Exp = "5"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-poc-ab-dev-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "cluster-subnet"
  address_prefixes     = ["10.1.0.0/21"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}


resource "azurerm_container_registry" "acr" {
  name                = "acrpocabdev001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-poc-ab-dev-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akspocab"

  default_node_pool {
    name           = "systempool"
    node_count     = 1
    vm_size        = "Standard_D2_v3"
    vnet_subnet_id = azurerm_subnet.subnet.id
    max_pods       = 40
    

    node_labels = {
      "type" = "system"
    }
  }

  network_profile {
    network_plugin = "azure"
    outbound_type  = "loadBalancer"
    network_policy = "azure"
    
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
    tenant_id          = "e4e34038-ea1f-4882-b6e8-ccd776459ca0"
  }

  role_based_access_control_enabled = true
}

resource "azurerm_kubernetes_cluster_node_pool" "userpool01" {
  name                  = "apppool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2_v3"
  node_count            = 2
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 6
  max_pods              = 40
  node_labels = {
    type = "user"
  }
}

# resource "azurerm_role_assignment" "admin" {
#   scope = azurerm_kubernetes_cluster.aks.id
#   role_definition_name = "Azure Kubernetes Service Cluster User Role"
#   principal_id = "b263832f-56f2-4132-87eb-d1bcaf1a84c6"
# }

# resource "azurerm_role_assignment" "namespace-groups" {
#   scope = azurerm_kubernetes_cluster.aks.id
#   role_definition_name = "Azure Kubernetes Service Cluster User Role"
#   principal_id = "47bb46e1-7e16-44ab-8a10-341641890014"
# }


