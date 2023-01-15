// ----------------------------------------------------------------------------
// Configure providers
// ----------------------------------------------------------------------------
# provider "helm" {
#   kubernetes {
#     host                   = module.cluster.cluster_host
#     cluster_ca_certificate = module.cluster.cluster_ca_certificate
#     token                  = module.cluster.cluster_token
#   }
# }

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "random_pet" "current" {
  prefix    = "tf-jx"
  separator = "-"
  keepers = {
    # Keep the name consistent on executions
    cluster_name = var.cluster_name
  }
}

data "aws_caller_identity" "current" {}

// ----------------------------------------------------------------------------
// Setup all required AWS resources as well as the EKS cluster and any k8s resources
// See https://www.terraform.io/docs/providers/aws/r/vpc.html
// See https://www.terraform.io/docs/providers/aws/r/eks_cluster.html
// ----------------------------------------------------------------------------
module "cluster" {
  source                                = "./modules/cluster"
  region                                = var.region
  create_eks                            = var.create_eks
  create_vpc                            = var.create_vpc
  vpc_id                                = var.vpc_id
  subnets                               = var.subnets
  cluster_name                          = var.cluster_name
  cluster_version                       = var.cluster_version
}
