output "aks_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}
