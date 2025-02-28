###################################
# Provider
###################################
terraform {
  required_version = ">= 1.4.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"   # Wymagamy wersji 4.x.x lub nowszej
    }
  }
}

###################################
# Log Analytics Workspace for OMS Agent
###################################
resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.aks_cluster_name}-log-analytics"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

###################################
# Resource Group
###################################
resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}

###################################
# Virtual Network and Subnet
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
# AKS Cluster Configuration
###################################
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_cluster_name

  # Nowy sposób ograniczenia dostępu do API serwera AKS
  api_server_access_profile {
    authorized_ip_ranges = var.aks_cluster_authorized_ip   # Upewnij się, że zmienna jest listą adresów CIDR
  }

  # addon_profile {
  #  kube_dashboard {
  #    enabled = false
  #  }
  #  oms_agent {
  #    enabled                    = true
  #    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  #  }
  # }

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
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
    dns_service_ip    = "10.0.0.10"
    service_cidr      = "10.0.0.0/16"
  }

  tags = {
    Environment = "Development"
  }
}

###################################
# Opcjonalny: Dodatkowa pula węzłów
###################################
resource "azurerm_kubernetes_cluster_node_pool" "extra_pool" {
  count                 = var.enable_additional_pool ? 1 : 0
  name                  = var.additional_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.additional_pool_vm_size
  node_count            = var.additional_pool_node_count
  max_pods              = 110

  min_count = var.additional_pool_min_count
  max_count = var.additional_pool_max_count

  node_labels = {
    "pool" = var.additional_pool_name
  }

  priority        = var.additional_pool_mode == "Spot" ? "Spot" : "Regular"
  eviction_policy = var.additional_pool_mode == "Spot" ? "Delete" : null
  spot_max_price  = var.additional_pool_mode == "Spot" ? -1 : null

  mode = "User"
}

###################################
# Public IP (przykład)
###################################
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
