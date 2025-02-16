# ArgoCD Installation and Vault Integration in EKS Cluster

This guide outlines the process of setting up ArgoCD in an EKS cluster, configuring the ArgoCD Vault Plugin (AVP), and managing secrets. We'll also demonstrate how to update secrets in Vault and automatically sync changes to Kubernetes via ArgoCD.

## Repository Structure
```
.
├── argocd.tf                # Terraform configuration for deploying ArgoCD
├── eks_provider.tf          # EKS and Kubernetes provider setup
├── main.tf                  # Entry point for Terraform configuration
├── templates                # YAML templates for ArgoCD and AVP
│   ├── argo.yaml
│   ├── avp-helm.yaml
│   ├── avp-k8s.yaml
│   └── avp-kustomize.yaml
├── variables.tf             # Terraform variable definitions
├── vault-plugin.tf          # Configuration for Vault plugin and secrets management
└── versions.tf              # Provider and Terraform version constraints
```

---

## Prerequisites

1. **AWS CLI**: Installed and configured with appropriate IAM permissions.
2. **kubectl**: Installed and configured to interact with your EKS cluster.
3. **Terraform**: Version >= 1.3.2.
4. **Helm**: Installed for deploying Helm charts.
5. **Vault**: Accessible for managing secrets.

---

## Steps to Set Up

### 1. Install ArgoCD in EKS Cluster

- The `argocd.tf` file deploys ArgoCD using the Helm provider.

```hcl
resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"

  values = [file("${path.module}/templates/argo.yaml")]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = local.admin_password != "" ? bcrypt(local.admin_password) : ""
  }

  set {
    name  = "configs.params.server\.insecure"
    value = true
  }
}
```

Run the following commands to apply the configuration:

```bash
terraform init
terraform apply
```

### 2. Configure ArgoCD Vault Plugin

- Deploy the ConfigMap and Secret for the ArgoCD Vault Plugin.

```hcl
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
```

### 3. Create and Manage Secrets in ArgoCD

- Use the `vault-plugin.tf` file to integrate AWS Secrets Manager with Vault and ArgoCD.

### 4. Update Secrets and Sync Changes

- Update secrets in Vault, and ArgoCD will automatically synchronize changes to the Kubernetes cluster using the Vault plugin.

---

## Cleanup

To remove all resources created during this setup, run the following command:

```bash
terraform destroy
```

---

## Additional Topics Covered

- Using tokens to fetch secrets.
- Automatic synchronization of secret updates.
- Best practices for secret management.

---

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Vault Plugin](https://github.com/argoproj-labs/argocd-vault-plugin)
- [Terraform Documentation](https://www.terraform.io/docs/index.html)

## Approle
1. vault auth enable approle

2. vault write auth/approle/role/argocd-avp \
    token_type=batch \
    secret_id_ttl=10m \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40

3. create and attach policy - vault write auth/approle/role/argocd-avp policies=argo-avp-policy
```json
path "auth/approle/login" {
  capabilities = ["create", "read", "update"]
}

path "argo/*" {
  capabilities = ["read", "list"]
}
```
4. vault read auth/approle/role/argocd-avp/role-id

5. vault write -f auth/approle/role/argocd-avp/secret-id

