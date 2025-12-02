
# Confidential variables
variable "local_machine_ip" {}
variable "cidr_block" {}
variable "pub-sub-count" {}
variable "pri-sub-count" {}
variable "pub-sub-block" {
  type = list(string)
}
variable "pri-sub-block" {
  type = list(string)
}
variable "ami" {}
variable "instance_type" {}
variable "cluster_base_name" {}
variable "eks_version" {}
variable "endpoint_private_access" {}
variable "endpoint_public_access" {}
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
    name    = string
    version = string
  }))
}

# Normal variables
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "env" {
  type    = string
  default = "prod"
}

variable "disk_size" {
  type    = number
  default = 50
}

variable "jump_server_disk_size" {
  type    = number
  default = 30
}

variable "is_eks_role_enabled" {
  type    = bool
  default = true
}

variable "is_eks_nodegroup_role_enabled" {
  type    = bool
  default = true
}

variable "is_cluster_enabled" {
  type    = bool
  default = true
}

# local variables
locals {
  cluster_name        = "${var.cluster_base_name}-${var.env}-cluster"
  security_group_name = "${local.cluster_name}-sg"
}
