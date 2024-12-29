resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  atomic           = true
  cleanup_on_fail  = true
  timeout          = 800
  values = [
    file("${path.module}/templates/argocd_values.yaml")
  ]
  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = local.workspace.admin_password == "" ? "" : bcrypt(local.workspace.admin_password)
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = true
  }
}