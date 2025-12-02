
variable "local_machine_ip" {}
variable "region" {}
variable "env" {}
variable "cidr_block" {}
variable "cluster_base_name" {}
variable "eks_version" {}
variable "pub-sub-count" {}
variable "pub-sub-block" {
  type = list(string)
}
variable "azs" {
  type = list(string)
}
variable "pri-sub-count" {}
variable "pri-sub-block" {
  type = list(string)
}
variable "endpoint_private_access" {}
variable "endpoint_public_access" {}
variable "disk_size" {}
variable "ami" {}
variable "instance_type" {}
variable "jump_server_disk_size" {}
variable "is_eks_role_enabled" {}
variable "is_eks_nodegroup_role_enabled" {}
variable "is_cluster_enabled" {}
variable "ondemand_instance_types" {
  type = list(string)
}
variable "ondemand_desired_capacity" {}
variable "ondemand_max_size" {}
variable "ondemand_min_size" {}
variable "spot_instance_types" {
  type = list(string)
}
variable "spot_desired_capacity" {}
variable "spot_max_size" {}   
variable "spot_min_size" {}
variable "addons" {
  type = list(object({
    name = string
    version = string
  }))
}
locals {
  cluster_name = "${var.cluster_base_name}-${var.env}-cluster"
  security_group_name = "${local.cluster_name}-sg"
}