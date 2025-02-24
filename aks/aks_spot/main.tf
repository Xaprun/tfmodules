terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

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
  }

  tags = {
    Environment = "Development"
  }
}

# Dodatkowa pula węzłów (opcjonalna)
resource "azurerm_kubernetes_cluster_node_pool" "extra_pool" {
  count                  = var.enable_additional_pool ? 1 : 0
  name                   = var.additional_pool_name
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks.id
  vm_size                = var.additional_pool_vm_size
  node_count             = var.additional_pool_node_count
  max_pods               = 110

  # Auto-scaling za pomocą scale_settings
  scale_settings {
    mode      = "AutoScale"
    min_size  = var.additional_pool_min_count
    max_size  = var.additional_pool_max_count
  }

  # Etykiety dla dodatkowej puli
  node_labels = {
    "pool" = var.additional_pool_name
  }

  # W zależności od trybu puli (Standard/Spot)
  priority        = var.additional_pool_mode == "Spot" ? "Spot" : "Regular"
  eviction_policy = var.additional_pool_mode == "Spot" ? "Delete" : null
  spot_max_price  = var.additional_pool_mode == "Spot" ? -1 : null

  # Można również ustawić orchestrator_version
  # orchestrator_version = azurerm_kubernetes_cluster.aks.kubernetes_version

  # Tryb puli: User (zalecany dla dodatkowych pooli)
  mode = "User"
}

# Public IP (przykład)
resource "azurerm_public_ip" "example" {
  count               = 1
  name                = "${var.aks_cluster_name}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}
