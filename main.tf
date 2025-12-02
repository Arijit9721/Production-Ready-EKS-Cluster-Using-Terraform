module "eks" {
  source = "./modules"

  # vpc variables
  local_machine_ip      = var.local_machine_ip
  region                = var.region
  env                   = var.env
  azs                   = var.azs
  cidr_block            = var.cidr_block
  pub-sub-block         = var.pub-sub-block
  pub-sub-count         = var.pub-sub-count
  pri-sub-block         = var.pri-sub-block
  pri-sub-count         = var.pri-sub-count
  ami                   = var.ami
  instance_type         = var.instance_type
  jump_server_disk_size = var.jump_server_disk_size

  # eks variables
  cluster_base_name             = var.cluster_base_name
  eks_version                   = var.eks_version
  endpoint_private_access       = var.endpoint_private_access
  endpoint_public_access        = var.endpoint_public_access
  ondemand_instance_types       = var.ondemand_instance_types
  ondemand_desired_capacity     = var.ondemand_desired_capacity
  ondemand_max_size             = var.ondemand_max_size
  ondemand_min_size             = var.ondemand_min_size
  spot_instance_types           = var.spot_instance_types
  spot_desired_capacity         = var.spot_desired_capacity
  spot_max_size                 = var.spot_max_size
  spot_min_size                 = var.spot_min_size
  addons                        = var.addons
  is_eks_role_enabled           = var.is_eks_role_enabled
  is_eks_nodegroup_role_enabled = var.is_eks_nodegroup_role_enabled
  is_cluster_enabled            = var.is_cluster_enabled
  disk_size                     = var.disk_size
}
    