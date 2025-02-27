###################################
# Provider
###################################
terraform {
  required_version = ">= 1.4.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.64.0"
    }
  }
}
###################################
# RG to group all resources
###################################
resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}

###################################
# Private network and subnet
###################################
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

###################################
# AKS cluster configuration
###################################
resource "azurerm_kubernetes_cluster" "aks" {
  name                            = var.aks_cluster_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  dns_prefix                      = var.aks_cluster_name
  api_server_authorized_ip_ranges = var.aks_cluster_authorized_ip   #["192.168.", "192.168.0.0/16"]

  depends_on = [
    azurerm_resource_group.aks_rg,
    azurerm_subnet.aks_subnet
  ]

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    network_policy     = "azure"
    dns_service_ip     = "10.0.0.10"
    # docker_bridge_cidr = "172.17.0.1/16" # excuded due to validation  process
    service_cidr       = "10.0.0.0/16"
  }

  tags = {
    Environment = "Development"
  }
}

# Dodatkowa pula węzłów (opcjonalna)
resource "azurerm_kubernetes_cluster_node_pool" "extra_pool" {
  count                 = var.enable_additional_pool ? 1 : 0
  name                  = var.additional_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.additional_pool_vm_size
  node_count            = var.additional_pool_node_count
  max_pods              = 110

  # Zamiana scale_settings na enable_auto_scaling
  # enable_auto_scaling = true
  min_count = var.additional_pool_min_count
  max_count = var.additional_pool_max_count

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
  depends_on = [
    azurerm_resource_group.aks_rg
  ]
}
