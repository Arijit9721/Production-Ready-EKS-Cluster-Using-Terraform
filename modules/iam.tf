
# random integers for unique resource naming
resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}

# IAM Role for Jump Server
resource "aws_iam_role" "jump-server-role" {
  name = "${var.env}-jump-server-role-${random_integer.random_suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for the jump server role
resource "aws_iam_policy" "jump-server-role-policy" {
  name = "${var.env}-jump-server-role-policy"
  policy = jsonencode({ 
    Version = "2012-10-17"
    Statement = [
      # 1. Core EKS Management (eksctl and kubectl setup)
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:UpdateNodegroupConfig",
          "eks:ListNodegroups",
        ]
        Resource = aws_eks_cluster.eks-cluster[0].arn
      },
      # 2. IAM Management (Necessary for Terraform/eksctl to create Node Group roles)
      {
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:ListRoles",
          "iam:ListRoleTags",
        ]
        Resource = [aws_iam_role.eks_nodegroup_role[0].arn, aws_iam_role.eks_cluster_role[0].arn] 
      },
      # 3. EC2 and Networking (Necessary for VPC, Subnets, Security Groups, EC2 instances)
      {
        Effect = "Allow"
        Action = [
          "ec2:*", 
          "autoscaling:*", 
        ]
        Resource = "*"
      },
      # 4. S3 Access (For state file management)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::arijit21-s3-backend-terraform",
          "arn:aws:s3:::arijit21-s3-backend-terraform/*"
        ]
      },
      # 5. SSM (Allows interaction with System Manager for potential remote commands)
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:DescribeParameters",
        ]
        Resource = "*"
      },
    ]
  })
}

# Attaches the management policy to your existing Jump Server Role
resource "aws_iam_role_policy_attachment" "jump_server_management_attach" {
  role       = aws_iam_role.jump-server-role.name
  policy_arn = aws_iam_policy.jump-server-role-policy.arn
}

# Jump server role instance profile
resource "aws_iam_instance_profile" "jump-server-instance-profile" {
  name = "${var.env}-jump-server-instance-profile"
  role = aws_iam_role.jump-server-role.name
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  count = var.is_eks_role_enabled ? 1 : 0 # works only if eks role is not already enabled
  name  = "${local.cluster_name}-eks-cluster-role-${random_integer.random_suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonEKSClusterPolicy to the EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count = var.is_eks_role_enabled ? 1 : 0 # works only if eks role is not already enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster_role[count.index].name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_nodegroup_role" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0 # works only if eks nodegroup role is not already enabled
  name  = "${local.cluster_name}-eks-nodegroup-role-${random_integer.random_suffix.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attaching necessary policies to the EKS Node Group Role
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0 # works only if eks nodegroup role is not already enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodegroup_role[count.index].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0 # works only if eks nodegroup role is not already enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodegroup_role[count.index].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0 # works only if eks nodegroup role is not already enabled
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodegroup_role[count.index].name
}

# role for eks oidc provider
resource "aws_iam_role" "eks_oidc_role" {
  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
  name = "eks-oidc-role-${random_integer.random_suffix.result}"
}