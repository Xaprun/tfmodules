# null_resource to wait for AKS cluster to be ready and fetch kubeconfig
resource "null_resource" "aks_ready" {
  provisioner "local-exec" {
    command = "echo 'Waiting for AKS to be ready...'"
    # command = "az aks get-credentials --resource-group tf-aks-we-rg --name tf-aks --file kubeconfig_aks"
    # command = "az aks get-credentials --resource-group tf-aks-we-rg --name tf-aks --overwrite-existing"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  # config_path = local_file.kubeconfig.filename
  # host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  # client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  # client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  # cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [null_resource.aks_ready]
}

# Check if the AKS cluster is available
resource "null_resource" "check_cluster" {
  provisioner "local-exec" {
    command = "kubectl get nodes --kubeconfig=kubeconfig_aks"
  }

  depends_on = [null_resource.aks_ready]
}


# resource "helm_release" "argo_cd" {
#   name       = "argo-cd"
#   namespace  =  kubernetes_namespace.argocd.metadata[0].name
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = "3.28.1"

#   #  values = [
#   #    file("${path.module}/argocd-values.yaml")
#   #  ]
#    depends_on = [kubernetes_namespace.argocd]
# }


