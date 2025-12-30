# odkomentuj moduł, kiedy SP uzyska prawo do nadawania ról
# resource "azurerm_role_assignment" "aks_ci_writer" {
#  scope                = azurerm_kubernetes_cluster.this.id
#  role_definition_name = "Azure Kubernetes Service RBAC Writer"
#  principal_id         = var.aks_ci_sp_object_id

#  depends_on = [
#    azurerm_kubernetes_cluster.this
#  ]
#}

variable "aks_ci_sp_object_id" {
  description = "Object ID of Service Principal used by CI/CD"
  type        = string
}
