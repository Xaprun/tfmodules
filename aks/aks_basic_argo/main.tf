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
resource "azurerm_log_analytics_workspace" "alaw_aks" {
  name                = "${var.aks_cluster_name}-log-analytics"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  # usually 30
  retention_in_days = 7

  tags = local.common_tags 
}

####################################################
###################  PROMETHEUS  ###################
####################################################

# Tworzenie konfiguracji monitoringu dla klastra AKS
resource "azurerm_kubernetes_cluster_monitoring" "akcm" {
  depends_on          = [azurerm_kubernetes_cluster.aks, azurerm_log_analytics_workspace.alaw_aks]
  cluster_id          = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.alaw_aks.id
}

# Tworzenie usługi zarządzanego Prometheusa
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name               = "aks-diagnostics"
  target_resource_id = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.alaw_aks.id

   dynamic "log" {
    for_each = [
      "kube-apiserver",
      "kube-controller-manager",
      "kube-scheduler",
      "cluster-autoscaler",
      "guard",
      "kube-audit",
      "kube-audit-admin",
      "kube-audit-error",
      "kube-authentication",
      "kube-authentication-error"
    ]

    content {
      category = log.value
      enabled  = true
      retention_policy {
        days    = 30
        enabled = true
      }
    }
  }

  dynamic "metric" {
    for_each = [
      "AllMetrics"
    ]

    content {
      category = metric.value
      enabled  = true
      retention_policy {
        days    = 30
        enabled = true
      }
    }
  }
}