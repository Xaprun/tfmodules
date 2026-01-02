output "aks_identity_principal_id" {
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
  description = "AKS system-assigned managed identity principalId"
}

output "kubelet_identity_object_id" {
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id, null)
  description = "Kubelet identity objectId"
}

output "kubelet_identity_client_id" {
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].client_id, null)
  description = "Kubelet identity clientId"
}

output "kubelet_identity_resource_id" {
  value       = try(azurerm_kubernetes_cluster.this.kubelet_identity[0].resource_id, null)
  description = "Kubelet identity resourceId"
}


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


###############################
# Kubeconfig (OPTIONAL – legacy / bootstrap only)
###############################

output "kube_config_raw" {
  description = "Raw kubeconfig (USE ONLY FOR BOOTSTRAP / DEBUG)"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}
