// ----------------------------------------------------------------------------
// Configure providers
// ----------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    host                   = module.cluster.cluster_host
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
    token                  = module.cluster.cluster_token
  }
}

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
  # desired_node_count                    = var.desired_node_count
  # min_node_count                        = var.min_node_count
  # max_node_count                        = var.max_node_count
  # node_machine_type                     = var.node_machine_type
  # node_groups                           = var.node_groups_managed
  # spot_price                            = var.spot_price
  # encrypt_volume_self                   = var.encrypt_volume_self
  # vpc_name                              = var.vpc_name
  # public_subnets                        = var.public_subnets
  # private_subnets                       = var.private_subnets
  # vpc_cidr_block                        = var.vpc_cidr_block
  # enable_nat_gateway                    = var.enable_nat_gateway
  # single_nat_gateway                    = var.single_nat_gateway
  # force_destroy                         = var.force_destroy
  # enable_spot_instances                 = var.enable_spot_instances
  # node_group_disk_size                  = var.node_group_disk_size
  # enable_worker_group                   = var.enable_worker_group
  # cluster_in_private_subnet             = var.cluster_in_private_subnet
  # map_accounts                          = var.map_accounts
  # map_roles                             = var.map_roles
  # map_users                             = var.map_users
  # enable_key_name                       = var.enable_key_name
  # key_name                              = var.key_name
  # volume_type                           = var.volume_type
  # volume_size                           = var.volume_size
  # iops                                  = var.iops
  # use_kms_s3                            = var.use_kms_s3
  # s3_kms_arn                            = var.s3_kms_arn
  # #content                               = local.content
  # cluster_endpoint_public_access        = var.cluster_endpoint_public_access
  # cluster_endpoint_public_access_cidrs  = var.cluster_endpoint_public_access_cidrs
  # cluster_endpoint_private_access       = var.cluster_endpoint_private_access
  # cluster_endpoint_private_access_cidrs = var.cluster_endpoint_private_access_cidrs
  # enable_worker_groups_launch_template  = var.enable_worker_groups_launch_template
  # allowed_spot_instance_types           = var.allowed_spot_instance_types
  # lt_desired_nodes_per_subnet           = var.lt_desired_nodes_per_subnet
  # lt_min_nodes_per_subnet               = var.lt_min_nodes_per_subnet
  # lt_max_nodes_per_subnet               = var.lt_max_nodes_per_subnet
  # cluster_encryption_config             = var.cluster_encryption_config
  # create_autoscaler_role                = var.create_autoscaler_role
  # create_bucketrepo_role                = var.create_bucketrepo_role
  # create_cm_role                        = var.create_cm_role
  # create_cmcainjector_role              = var.create_cmcainjector_role
  # create_ctrlb_role                     = var.create_ctrlb_role
  # create_exdns_role                     = var.create_exdns_role
  # create_pipeline_vis_role              = var.create_pipeline_vis_role
  # create_asm_role                       = var.create_asm_role
  # create_ssm_role                       = var.create_ssm_role
  # create_tekton_role                    = var.create_tekton_role
  # additional_tekton_role_policy_arns    = var.additional_tekton_role_policy_arns
  # tls_cert                              = var.tls_cert
  # tls_key                               = var.tls_key
}
