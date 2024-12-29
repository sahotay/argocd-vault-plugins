locals {
  region           = "us-east-2"
  eks_cluster_name = "eks-cluster-automode"
  admin_password   = "admin"
}

variable "admin_role" {
  description = "Admin IAM role to create EKS cluster"
}