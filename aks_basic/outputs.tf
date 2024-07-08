output "kube_config" {
  description = "Kube config file content"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
}

# output "aks_ip_address" {
#   value = azurerm_kubernetes_cluster.aks.kubernetes_network_profile.load_balancer_profile.effective_outbound_ips[0].ip_address
# }

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}