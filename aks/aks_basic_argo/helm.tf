# null_resource to wait for AKS cluster to be ready
resource "null_resource" "wait_for_aks" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group tf-aks-we-rg --name tf-aks --overwrite-existing"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}
resource "null_resource" "wait_for_aks_2" {
  provisioner "local-exec" {
    command = "echo 'Waiting for AKS to be ready...'"
    # command = "echo 'Waiting for AKS to be ready...' && sleep 120"
  }
  depends_on = [null_resource.wait_for_aks]
}



provider "kubernetes" {
  config_path = "~/.kube/config"
  depends_on  = [null_resource.wait_for_aks]
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}




resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  namespace  =  kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.28.1"

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
  depends_on = [kubernetes_namespace.argocd]
}


