resource "kubernetes_config_map" "cmp-plugin" {
  metadata {
    name      = "avp-cmp-plugin"
    namespace = "argocd"
  }
  data = {
    "avp-kustomize.yaml" = templatefile("${path.module}/templates/avp-kustomize.yaml", { name = "avp-kustomize" })
    "avp-helm.yaml"      = templatefile("${path.module}/templates/avp-helm.yaml", { name = "avp-helm" })
    "avp-k8s.yaml"       = templatefile("${path.module}/templates/avp-k8s.yaml", { name = "avp-k8s" })
  }
}


data "aws_secretsmanager_secret_version" "vault_credentials" {
  secret_id = "vault/techtalk"
}


resource "kubernetes_secret" "vault_credentials" {
  metadata {
    name      = "avp-plugin-credentials"
    namespace = "argocd"
  }
  data = {
    VAULT_ADDR    = jsondecode(data.aws_secretsmanager_secret_version.vault_credentials.secret_string)["VAULT_ADDR"]
    AVP_AUTH_TYPE = jsondecode(data.aws_secretsmanager_secret_version.vault_credentials.secret_string)["AVP_AUTH_TYPE"]
    AVP_TYPE      = jsondecode(data.aws_secretsmanager_secret_version.vault_credentials.secret_string)["AVP_TYPE"]
    VAULT_TOKEN   = jsondecode(data.aws_secretsmanager_secret_version.vault_credentials.secret_string)["VAULT_TOKEN"]
  }
  type       = "Opaque"
  depends_on = [kubernetes_config_map.cmp-plugin]
}