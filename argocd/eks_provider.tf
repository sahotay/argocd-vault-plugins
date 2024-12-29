data "aws_eks_cluster_auth" "selected" {
  name = local.eks_cluster_name
}

data "aws_eks_cluster" "selected" {
  name = local.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.selected.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.selected.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.selected.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.selected.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.selected.token
  }
}