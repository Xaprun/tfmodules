output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_fqdn" {
  description = "AKS FQDN"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "aks_id" {
  description = "AKS resource ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "node_resource_group" {
  description = "AKS node resource group"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}
