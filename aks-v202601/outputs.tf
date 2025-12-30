###############################
# AKS – Core
###############################

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_id" {
  description = "AKS resource ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "aks_location" {
  description = "AKS location"
  value       = azurerm_kubernetes_cluster.this.location
}

###############################
# AKS – Networking / Access
###############################

output "aks_fqdn" {
  description = "AKS public FQDN (null for private cluster)"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "aks_private_fqdn" {
  description = "AKS private FQDN (only for private cluster)"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "private_cluster_enabled" {
  description = "Whether AKS is private"
  value       = azurerm_kubernetes_cluster.this.private_cluster_enabled
}

###############################
# AKS – Identity / Security
###############################

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "AKS node resource group name"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "AKS node resource group ID"
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

###############################
# Observability – Managed Prometheus
###############################

output "azure_monitor_workspace_id" {
  description = "Azure Monitor Workspace ID (Managed Prometheus)"
  value       = try(azurerm_monitor_workspace.this.id, null)
}

output "azure_monitor_workspace_name" {
  description = "Azure Monitor Workspace name"
  value       = try(azurerm_monitor_workspace.this.name, null)
}

###############################
# Kubeconfig (OPTIONAL – legacy / bootstrap only)
###############################

output "kube_config_raw" {
  description = "Raw kubeconfig (USE ONLY FOR BOOTSTRAP / DEBUG)"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}
