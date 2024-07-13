# null_resource to wait for AKS cluster to be ready and fetch kubeconfig
resource "null_resource" "aks_ready" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group tf-aks-we-rg --name tf-aks --overwrite-existing"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  # config_path = local_file.kubeconfig.filename
  # host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  # client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  # client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  # cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

#Install Argo CD using Helm
resource "null_resource" "install_argocd" {
  provisioner "local-exec" {
    command = "helm repo add argo https://argoproj.github.io/argo-helm && helm repo update && helm install argo-cd argo/argo-cd --namespace argocd --create-namespace"
  }
  #depends_on = [null_resource.create_namespace]
  depends_on = [null_resource.aks_ready]
}

# NIE DZIAŁA
# resource "kubernetes_namespace" "argocd" {
#   metadata {
#     name = "argocd"
#   }
#   depends_on = [null_resource.aks_ready]
# }

