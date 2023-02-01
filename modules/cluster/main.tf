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
  source  = "terraform-aws-modules/eks/aws"
  # version = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    # coredns = {
    #   resolve_conflicts = "OVERWRITE"
    # }
    # kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
  }
  

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["r6i.large"]    #["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  # eks_managed_node_groups = {
  #   # blue = {}
  #   # extend_config = {
  #   #     bootstrap_extra_args = "--container-runtime containerd --kubelet-extra-args '--max-pods=110'"
        
  #   #     pre_bootstrap_user_data = <<-EOT
  #   #     export CONTAINER_RUNTIME="containerd"
  #   #     export USE_MAX_PODS=false
  #   #     EOT
  #   # }

  #   # green = {
  #   #   create_launch_template = false
  #   #   launch_template_name   = ""

  #   #   min_size     = 1
  #   #   max_size     = 10
  #   #   desired_size = 1

  #   #   instance_types = ["r6i.large"]
  #   #   capacity_type  = "ON-DEMAND"
  #   #   enable_bootstrap_user_data = true

  #   #   kubelet_extra_args = "--max-pods=110"

  #   #   pre_bootstrap_user_data = <<-EOT
  #   #     export CONTAINER_RUNTIME="containerd"
  #   #     export USE_MAX_PODS=false
  #   #     EOT
  #   # }
  #   group_name = {
  #     create_launch_template = false
  #     launch_template_name = ""

  #     pre_bootstrap_user_data = <<-EOT
  #     #!/bin/bash
  #     set -ex
  #     cat <<-EOF > /etc/profile.d/bootstrap.sh
  #     export CONTAINER_RUNTIME="containerd"
  #     export USE_MAX_PODS=false
  #     EOF
  #     # Source extra environment variables in bootstrap script
  #     sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
  #     EOT
  #   }
  #   # blueblack = {
  #   #   name            = "complete-eks-mng"
  #   #   use_name_prefix = true

  #   #   subnet_ids = module.vpc.private_subnets

  #   #   min_size     = 1
  #   #   max_size     = 7
  #   #   desired_size = 1
  #   #   ami_type = "AL2_x86_64"
  #   #   subnets         = module.vpc.public_subnets
  #   #   pre_bootstrap_user_data = <<-EOT
  #   #     #!/bin/bash
  #   #     set -ex
  #   #     cat <<-EOF > /etc/profile.d/bootstrap.sh
  #   #     export CONTAINER_RUNTIME="containerd"
  #   #     export USE_MAX_PODS=false
  #   #     export KUBELET_EXTRA_ARGS="--max-pods=110 --instance-type r6i.large --cni-version 1.10.4 --cni-prefix-delegation-enabled")}"
  #   #     EOF
  #   #     # Source extra environment variables in bootstrap script
  #   #     sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
  #   #     EOT
      
  #   # }

    
  # }

  eks_managed_node_groups = {
    group_name = {
      ami_id = "ami-0eb9bd067e5d1e192" # set this to an EKS-optimized AMI from data resources (x86 and arm examples below)
      create_launch_template = true
      # launch_template_name = "" # optional if you want your own name

      enable_bootstrap_user_data = true
      bootstrap_extra_args = "--container-runtime containerd --kubelet-extra-args '--max-pods=110'"
    }
  }


    # mygrp-ng = {
    #   #  bootstrap_extra_args       = "--container-runtime containerd --kubelet-extra-args '--max-pods=110'"

    #   pre_bootstrap_user_data = <<-EOT
    #   #!/bin/bash
    #   set -ex
    #   cat <<-EOF > /etc/profile.d/bootstrap.sh
    #   export CONTAINER_RUNTIME="containerd"
    #   export USE_MAX_PODS=false
    #   export KUBELET_EXTRA_ARGS="--max-pods=110"
    #   EOF
    #   # Source extra environment variables in bootstrap script
    #   sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
    #   EOT

    #   post_bootstrap_user_data = <<-EOT
    #   echo "you are free little kubelet!"
    #   EOT

    #   capacity_type        = "SPOT"
    #   force_update_version = true
    # }


  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = module.eks.cluster_iam_role_arn
      username = "papu"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::657907747545:user/shahbaz"
      username = "shahbaz"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::657907747545:user/m.zakir"
      username = "zakir"
      groups   = ["system:masters"]
    },
  ]
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
