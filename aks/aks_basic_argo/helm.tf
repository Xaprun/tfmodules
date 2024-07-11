resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "3.28.1"

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}