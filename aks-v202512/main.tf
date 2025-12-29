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
  features {}
}

locals {
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Module      = "aks"
    }
  )
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : var.name

  kubernetes_version              = var.kubernetes_version
  private_cluster_enabled         = var.private_cluster_enabled
  role_based_access_control_enabled = true
  local_account_disabled          = var.local_account_disabled

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aad_admin_group_object_ids != null ? [1] : []
    content {
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aad_admin_group_object_ids
      tenant_id              = var.tenant_id
    }
  }

  dynamic "api_server_access_profile" {
    for_each = (!var.private_cluster_enabled && var.api_server_authorized_ip_ranges != null) ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  default_node_pool {
    name           = var.system_node_pool.name
    vm_size        = var.system_node_pool.vm_size
    node_count     = var.system_node_pool.node_count
    max_pods       = var.system_node_pool.max_pods
    vnet_subnet_id = var.vnet_subnet_id
    type           = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = var.network_policy
    load_balancer_sku = "standard"

    dns_service_ip = var.dns_service_ip
    service_cidr   = var.service_cidr
  }

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  count                 = var.user_node_pool != null ? 1 : 0
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id

  name       = var.user_node_pool.name
  vm_size    = var.user_node_pool.vm_size
  mode       = "User"
  max_pods   = var.user_node_pool.max_pods

  auto_scaling_enabled = var.user_node_pool.enable_auto_scaling
  node_count          = var.user_node_pool.enable_auto_scaling ? null : var.user_node_pool.node_count
  min_count           = var.user_node_pool.enable_auto_scaling ? var.user_node_pool.min_count : null
  max_count           = var.user_node_pool.enable_auto_scaling ? var.user_node_pool.max_count : null

  priority        = var.user_node_pool.spot ? "Spot" : "Regular"
  eviction_policy = var.user_node_pool.spot ? "Delete" : null
  spot_max_price  = var.user_node_pool.spot ? var.user_node_pool.spot_max_price : null

  lifecycle {
    ignore_changes = [node_count]
  }
}
