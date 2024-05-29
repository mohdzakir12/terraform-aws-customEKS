// ----------------------------------------------------------------------------
// Query necessary data for the module
// ----------------------------------------------------------------------------
data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

// ----------------------------------------------------------------------------
// Define K8s cluster configuration
// ----------------------------------------------------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    csi-snapshot-controller = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    pod-identity-webhook = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    s3-csi-driver = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    efs-csi-driver = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    cloudwatch-agent = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    adot = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  // EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 20
    instance_types = ["r6i.large"]
  }

  eks_managed_node_groups = {
    group_name = {
      ami_id = "ami-05d018b6c09ba06ab" // Ensure this is a valid EKS-optimized AMI ID
      create_launch_template = true

      enable_bootstrap_user_data = true
      bootstrap_extra_args = "--container-runtime containerd --kubelet-extra-args '--max-pods=110'"
    }
  }

  // aws-auth configmap
  aws_auth_roles = [
    {
      rolearn  = module.eks.cluster_iam_role_arn
      username = "papu"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::657907747545:user/m.zakir"
      username = "m.zakir"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::657907747545:user/eks"
      username = "eks"
      groups   = ["system:masters"]
    },
  ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
