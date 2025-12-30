terraform {
  required_version = ">= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}


provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
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

  log_analytics_workspace_id = coalesce(
    var.log_analytics_workspace_id,
    try(azurerm_log_analytics_workspace.this[0].id, null)
  )
}

# ---------------------------------------
# Optional Log Analytics (for oms_agent)
# ---------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  count               = var.enable_oms_agent && var.log_analytics_workspace_id == null ? 1 : 0
  name                = "${var.aks_cluster_name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days

  tags = local.tags_common
}

resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_oms_agent ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  
  workspace_resource_id = local.log_analytics_workspace_id
  # mod/fix w module observability
  workspace_name = var.log_analytics_workspace_id != null
    ? var.log_analytics_workspace_name
    : azurerm_log_analytics_workspace.this[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# added observability
# ma być w variables, ale na razie tyu ;)
validation {
  condition     = var.log_analytics_workspace_id == null || var.log_analytics_workspace_name != null
  error_message = "When log_analytics_workspace_id is set, log_analytics_workspace_name must also be provided."
}



# ---------------------------------------
# AKS
# ---------------------------------------
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = coalesce(var.dns_prefix, var.aks_cluster_name)

  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = var.private_cluster_enabled
  role_based_access_control_enabled = true

  # Authorized IP ranges:
  # - nie próbuj "wyłączać" tego pustą listą, bo provider ma z tym problemy;
  # - jeśli nie chcesz ograniczać, ustaw null i blok nie powstanie. :contentReference[oaicite:1]{index=1}
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

  # OMS Agent / Monitoring (opcjonalnie)
  dynamic "oms_agent" {
    for_each = var.enable_oms_agent ? [1] : []
    content {
      log_analytics_workspace_id = local.log_analytics_workspace_id
    }
  }

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

  # fix blokady usunięcia rg i LAW
  # aby umieścić zasób tworzony przez Azure w state i móc go usówać
  # mod w wersji observability
  depends_on = [
    azurerm_log_analytics_workspace.this,
    azurerm_log_analytics_solution.container_insights
  ]

  # na rzecz managed observability
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

  name       = var.additional_pool_name
  vm_size    = var.additional_pool_vm_size
  mode       = "User"
  max_pods   = var.additional_pool_max_pods

  auto_scaling_enabled = true
  node_count          = var.additional_pool_node_count
  min_count           = var.additional_pool_min_count
  max_count           = var.additional_pool_max_count

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

  name       = var.additional_pool_name
  vm_size    = var.additional_pool_vm_size
  mode       = "User"
  max_pods   = var.additional_pool_max_pods

  auto_scaling_enabled = false
  # enable_auto_scaling = false
  node_count          = var.additional_pool_node_count

  node_labels = {
    pool = var.additional_pool_name
  }

  priority        = var.additional_pool_mode == "Spot" ? "Spot" : "Regular"
  eviction_policy = var.additional_pool_mode == "Spot" ? "Delete" : null
  spot_max_price  = var.additional_pool_mode == "Spot" ? var.additional_pool_spot_max_price : null
}


# ---------------------------------------
# Managed observability
# ---------------------------------------

# Data Collection Rule (Prometheus)
resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                = "${var.aks_cluster_name}-prom-dcr"
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_account.prometheus.id
      name               = "metrics"
    }
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "prometheus"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["metrics"]
  }
}

# Azure Monitor Account (Managed Prometheus)
resource "azurerm_monitor_account" "prometheus" {
  name                = "${var.aks_cluster_name}-prom"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Podpięcie AKS → DCR:
resource "azurerm_monitor_data_collection_rule_association" "aks_prometheus" {
  name                    = "aks-prometheus"
  target_resource_id      = azurerm_kubernetes_cluster.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
}
