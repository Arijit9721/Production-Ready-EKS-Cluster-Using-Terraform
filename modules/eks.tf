resource "aws_eks_cluster" "eks-cluster" {
  count = var.is_cluster_enabled ? 1 : 0 # works only if eks cluster is enabled
  name = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role[count.index].arn
  version  = var.eks_version

  access_config {
    authentication_mode = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private-subnets[0].id,
      aws_subnet.private-subnets[1].id
    ]
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids = [aws_security_group.eks-cluster-sg.id]  
    }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy
  ]

    tags = {
        Name        = local.cluster_name
        Env         = var.env
    }
}

# EKS OIDC Provider
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url = data.tls_certificate.eks_cert.url
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cert.certificates[0].sha1_fingerprint] 
}

# Ondemand launch template (needed separately because remote access and launch template cannot be specified together in node group)
resource "aws_launch_template" "ondemand-template" {
  name_prefix = "${local.cluster_name}-ondemand-node-"
  vpc_security_group_ids = [aws_security_group.eks-node_group-sg.id]
  key_name = aws_key_pair.main-key.key_name
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.disk_size
      volume_type = "gp3"
    }
  }
}

# Ondemand Node Group
resource "aws_eks_node_group" "ondemand-node" {
  cluster_name    = aws_eks_cluster.eks-cluster[0].name
  node_group_name = "${local.cluster_name}-ondemand-nodes"
  node_role_arn   = aws_iam_role.eks_nodegroup_role[0].arn
  subnet_ids      = [aws_subnet.private-subnets[0].id, aws_subnet.private-subnets[1].id]
  instance_types  = var.ondemand_instance_types
  capacity_type = "ON_DEMAND"
  
  scaling_config {
    desired_size = var.ondemand_desired_capacity
    max_size     = var.ondemand_max_size
    min_size     = var.ondemand_min_size
  }

  launch_template {
    id = aws_launch_template.ondemand-template.id
    version = aws_launch_template.ondemand-template.latest_version
  }
  
  update_config {
    max_unavailable = 1
  }

  labels = {
    type = "ondemand"
  }

  tags = { "Name"  = "${local.cluster_name}-ondemand-nodes" }

  tags_all = {
  "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  "Name" = "${local.cluster_name}-ondemand-nodes"  
  }

  depends_on = [ aws_eks_cluster.eks-cluster ]
}

# Spot launch template (needed separately because remote access and launch template cannot be specified together in node group)
resource "aws_launch_template" "spot-template" {
  name_prefix = "${local.cluster_name}-spot-node-"
  vpc_security_group_ids = [aws_security_group.eks-node_group-sg.id]
  key_name = aws_key_pair.main-key.key_name
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.disk_size
      volume_type = "gp3"
    }
  }
}

# Spot Node Group
resource "aws_eks_node_group" "spot-node" {
  cluster_name    = aws_eks_cluster.eks-cluster[0].name
  node_group_name = "${local.cluster_name}-spot-nodes"
  node_role_arn   = aws_iam_role.eks_nodegroup_role[0].arn
  subnet_ids      = [aws_subnet.private-subnets[0].id, aws_subnet.private-subnets[1].id]
  instance_types  = var.spot_instance_types
  capacity_type = "SPOT"
  
  scaling_config {
    desired_size = var.spot_desired_capacity
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  launch_template {
    id = aws_launch_template.spot-template.id
    version = aws_launch_template.spot-template.latest_version
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    type = "spot"
    lifecycle = "spot"
  }

  tags = { "Name"  = "${local.cluster_name}-spot-nodes" }

  tags_all = {
  "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  "Name" = "${local.cluster_name}-spot-nodes"  
  }

  depends_on = [ aws_eks_cluster.eks-cluster ]
}

# Addon for EKS Cluster
resource "aws_eks_addon" "eks_addons" {
  for_each = {for index, addon in var.addons : index => addon} # converting the addons variable to a map for iteration
  cluster_name = aws_eks_cluster.eks-cluster[0].name
  addon_name   = each.value.name
  addon_version = each.value.version

  depends_on = [ aws_eks_node_group.ondemand-node , aws_eks_node_group.spot-node ]
}
