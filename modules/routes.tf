# Route Table for the Internet Gateway
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "${var.env}-public-route-table"
    Env = var.env
  }

  depends_on = [ aws_internet_gateway.main-igw ]
}

# Route Table Association for Internet Gateway and Public Subnets
resource "aws_route_table_association" "pub_sub-igw-association" {
  count = var.pub-sub-count
  subnet_id = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.public-rt.id

  depends_on = [ aws_subnet.public-subnets, aws_route_table.public-rt ]
}
   
# Route Table for Nat Gateway
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pub_sub_nat.id
  }

  tags = {
    Name = "${var.env}-private-route-table"
    Env = var.env
  }

  depends_on = [ aws_nat_gateway.pub_sub_nat ]
}

# Route Table Association for Nat Gateway and Private Subnets
resource "aws_route_table_association" "pri_sub-nat-association" {
  count = var.pri-sub-count
  subnet_id      = aws_subnet.private-subnets[count.index].id
  route_table_id = aws_route_table.private-route-table.id
  depends_on = [ aws_route_table.private-route-table, aws_nat_gateway.pub_sub_nat ]
} 

######      Security Groups for Jump Server, EKS Cluster and Nodes       ######

# Security Group for Jump Server
resource "aws_security_group" "jump-server-sg" {
  name = "${var.env}-jump-server-sg" 
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "${var.env}-jump-server-sg"
  } 
}

# Allow SSH access to Jump Server from the local machine
resource "aws_security_group_rule" "allow" {
  type = "ingress"
  protocol = "tcp"
  from_port = 22
  to_port = 22
  security_group_id = aws_security_group.jump-server-sg.id
  cidr_blocks = [var.local_machine_ip]
}

# Allow all outbound traffic from Jump Server
resource "aws_security_group_rule" "egress_all" {
  type = "egress"
  protocol = "-1"
  from_port = 0
  to_port = 0
  security_group_id = aws_security_group.jump-server-sg.id
  cidr_blocks = ["0.0.0.0/0"]
}



# Security group for the EKS cluster
resource "aws_security_group" "eks-cluster-sg" {
  name        = local.security_group_name
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main-vpc.id

  tags = {
    Name = local.security_group_name
    Environment = var.env
  }
}

# Allow Https from jump host to control plane
resource "aws_security_group_rule" "eks-cluster-sg-ingress" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.jump-server-sg.id
  security_group_id = aws_security_group.eks-cluster-sg.id
}

# Allow https from worker nodes to Control Plane
resource "aws_security_group_rule" "eks-cluster-sg-ingress-from-nodes" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  source_security_group_id = aws_security_group.eks-node_group-sg.id
  security_group_id = aws_security_group.eks-cluster-sg.id
}

# egress rule to allow all outbound traffic
resource "aws_security_group_rule" "eks-cluster-sg-egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks-cluster-sg.id
}




# Security Group for EKS Nodes
resource "aws_security_group" "eks-node_group-sg" {
  name        = "${local.cluster_name}-node_group-sg"
  description = "Security group for EKS Worker Nodes"
  vpc_id      = aws_vpc.main-vpc.id

  tags = {
    Name = "${local.cluster_name}-node_group-sg"
    Environment = var.env
  }
}

# Allow nodes to communicate with each other (Mesh/CNI)
resource "aws_security_group_rule" "nodes_ingress_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-node_group-sg.id
  source_security_group_id = aws_security_group.eks-node_group-sg.id
}

# Allow Control Plane to communicate with Nodes 
resource "aws_security_group_rule" "nodes_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node_group-sg.id
  source_security_group_id = aws_security_group.eks-cluster-sg.id
}

# Allow 443 from Control Plane 
resource "aws_security_group_rule" "nodes_ingress_https_from_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node_group-sg.id
  source_security_group_id = aws_security_group.eks-cluster-sg.id
}

# Allow SSH from Jump Server to Worker Nodes for debugging
resource "aws_security_group_rule" "nodes_ingress_ssh_from_jump_server" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-node_group-sg.id
  source_security_group_id = aws_security_group.jump-server-sg.id
}

# Allow all outbound Traffic flows to NAT Gateway 
resource "aws_security_group_rule" "nodes_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks-node_group-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}