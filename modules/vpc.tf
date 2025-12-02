# The main vpc for production environment
resource "aws_vpc" "main-vpc" {
  cidr_block = var.cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

    tags = {
        Name = "${var.env}-vpc"
        Env = var.env
    }
}

# The internet gateway for the VPC
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "${var.env}-igw"
    Env = var.env
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  depends_on = [aws_vpc.main-vpc]
}

# Providing an Elastic IP to the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main-igw]
  tags = {
    Name = "${var.env}-nat-eip"
    Env  = var.env
  }
}

# NAT Gateway for Private Subnets
resource "aws_nat_gateway" "pub_sub_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-subnets[0].id

  tags = {
    Name = "${var.env}-nat-gateway"
    Env  = var.env
  }
  
  depends_on = [aws_internet_gateway.main-igw, aws_eip.nat_eip]
}


