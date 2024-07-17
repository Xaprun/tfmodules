####################################################
################  PROVIDER  ########################
####################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

####################################################
################ AKS Cluster #######################
####################################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_cluster_name

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy = "calico"
  }


  tags = merge(
    local.common_tags,
    {
      TagOption = "merged"
    }
  )
}

####################################################
################  Log Analytics  ###################
####################################################

# Tworzenie przestrzeni nazw Log Analytics
resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.aks_cluster_name}-log-analytics"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  # usually 30
  retention_in_days = 5

  tags = local.common_tags
 
  
}



