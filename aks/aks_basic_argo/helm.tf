# null_resource to wait for AKS cluster to be ready and fetch kubeconfig
resource "null_resource" "fetch_kubeconfig" {
  provisioner "local-exec" {
    command = "echo 'Waiting for AKS to be ready...'"
    # command = "az aks get-credentials --resource-group tf-aks-we-rg --name tf-aks --file kubeconfig_aks"
    # command = "az aks get-credentials --resource-group tf-aks-we-rg --name tf-aks --overwrite-existing"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# local_file to read the kubeconfig fetched by null_resource
resource "local_file" "kubeconfig" {
  content  = file("kubeconfig_aks")
  filename = "${path.module}/kubeconfig_aks"
}


provider "kubernetes" {
  # config_path = "~/.kube/config"
  config_path = local_file.kubeconfig.filename
  # depends_on  = [null_resource.fetch_kubeconfig]
  # host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  # client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  # client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  # cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  # The provider argument name "depends_on" is reserved for use by Terraform in a future version:
  # depends_on  = [null_resource.wait_for_aks]
}




resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [null_resource.fetch_kubeconfig]
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


