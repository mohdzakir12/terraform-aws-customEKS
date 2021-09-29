// ----------------------------------------------------------------------------
// Query necessary data for the module
// ----------------------------------------------------------------------------
# data "aws_eks_cluster" "cluster" {
#   name = var.create_eks ? module.eks.cluster_id : var.cluster_name
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = var.create_eks ? module.eks.cluster_id : var.cluster_name
# }

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

// ----------------------------------------------------------------------------
// Define K8s cluster configuration
// ----------------------------------------------------------------------------
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

// ----------------------------------------------------------------------------
// Create the AWS VPC
// See https://github.com/terraform-aws-modules/terraform-aws-vpc
// ----------------------------------------------------------------------------
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 2.70"
  create_vpc           = var.create_vpc
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr_block
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_dns_hostnames = true
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

//////////////////////////////////////////////////////////////////////
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"

  cluster_version = "1.20"
  cluster_name    = var.cluster_name #"my-cluster"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets

  # worker_groups = [
  #   {
  #     instance_type = var.instance_type
  #     asg_max_size  = 3
  #   }
  # ]

  # Managed Node Groups
  node_groups_defaults = {
    ami_type  = var.node_group_ami #"AL2_x86_64"
    disk_size = 50
  }

  node_groups = {
    dev-ng = {
      desired_capacity = 1
      max_capacity     = 10
      min_capacity     = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      k8s_labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      # additional_tags = {
      #   ExtraTag = "example"
      # }
      # taints = [
      #   {
      #     key    = "dedicated"
      #     value  = "gpuGroup"
      #     effect = "NO_SCHEDULE"
      #   }
      # ]
      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }
    }
  }
}