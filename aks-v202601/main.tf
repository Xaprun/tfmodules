terraform {
  required_version = ">= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

locals {
  tags_common = merge(
    var.tags,
    {
      Environment = var.environment
      Module      = "aks"
    }
  )
}

# ---------------------------------------
# AKS
# ---------------------------------------
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = coalesce(var.dns_prefix, var.aks_cluster_name)

  kubernetes_version              = var.kubernetes_version
  private_cluster_enabled         = var.private_cluster_enabled
  role_based_access_control_enabled = true

  # Authorized IP ranges (tylko dla public API i tylko gdy lista != null)
  dynamic "api_server_access_profile" {
    for_each = (!var.private_cluster_enabled && var.api_server_authorized_ip_ranges != null) ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # AAD / Azure RBAC dla AKS (opcjonalnie)
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aad_admin_group_object_ids != null ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aad_admin_group_object_ids
      tenant_id              = var.tenant_id
    }
  }

  local_account_disabled = (var.local_account_disabled && var.aad_admin_group_object_ids != null) ? true : false

  default_node_pool {
    name           = var.system_node_pool_name
    vm_size        = var.node_vm_size
    node_count     = var.node_count
    vnet_subnet_id = var.vnet_subnet_id
    max_pods       = var.system_max_pods
    type           = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = var.network_policy

    dns_service_ip = var.dns_service_ip
    service_cidr   = var.service_cidr
  }

  tags = local.tags_common

  # ---------------------------------------
  # Managed Prometheus (AKS built-in scrape pipeline)
  # ---------------------------------------
  # To nie jest "Container Insights". To jest nowy model metryk (Azure Monitor Managed Prometheus).
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

}

# ---------------------------------------
# Optional extra user node pool - autoscaling
# ---------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "extra_as" {
  count                 = (var.enable_additional_pool && var.additional_pool_enable_auto_scaling) ? 1 : 0
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id

  name     = var.additional_pool_name
  vm_size  = var.additional_pool_vm_size
  mode     = "User"
  max_pods = var.additional_pool_max_pods

  auto_scaling_enabled = true
  node_count           = var.additional_pool_node_count
  min_count            = var.additional_pool_min_count
  max_count            = var.additional_pool_max_count

  node_labels = {
    pool = var.additional_pool_name
  }

  priority        = var.additional_pool_mode == "Spot" ? "Spot" : "Regular"
  eviction_policy = var.additional_pool_mode == "Spot" ? "Delete" : null
  spot_max_price  = var.additional_pool_mode == "Spot" ? var.additional_pool_spot_max_price : null

  lifecycle {
    ignore_changes = [node_count]
  }
}

# ---------------------------------------
# Optional extra user node pool - fixed size
# ---------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "extra_fixed" {
  count                 = (var.enable_additional_pool && !var.additional_pool_enable_auto_scaling) ? 1 : 0
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id

  name     = var.additional_pool_name
  vm_size  = var.additional_pool_vm_size
  mode     = "User"
  max_pods = var.additional_pool_max_pods

  auto_scaling_enabled = false
  node_count           = var.additional_pool_node_count

  node_labels = {
    pool = var.additional_pool_name
  }

  priority        = var.additional_pool_mode == "Spot" ? "Spot" : "Regular"
  eviction_policy = var.additional_pool_mode == "Spot" ? "Delete" : null
  spot_max_price  = var.additional_pool_mode == "Spot" ? var.additional_pool_spot_max_price : null
}

# ---------------------------------------
# Managed Observability backend (Azure Monitor Workspace)
# ---------------------------------------

