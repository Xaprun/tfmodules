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
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
