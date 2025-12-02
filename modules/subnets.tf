
# public subnets for the vpc
resource "aws_subnet" "public-subnets" {
  count = var.pub-sub-count
  vpc_id = aws_vpc.main-vpc.owner_id
  cidr_block = element(var.pub-sub-block, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  depends_on = [ aws_vpc.main-vpc ]
    tags = {
        Name = "${local.cluster_name}-public-subnet-${count.index + 1}"
        Environment = var.env
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
        "kubernetes.io/role/elb" = "1"
    }
}

# private subnets for the vpc
resource "aws_subnet" "private-subnets" {
  count = var.pri-sub-count
  vpc_id = aws_vpc.main-vpc.owner_id
  cidr_block = element(var.pri-sub-block, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = false

  depends_on = [ aws_vpc.main-vpc ]
    tags = {
        Name = "${local.cluster_name}-private-subnet-${count.index + 1}"
        Environment = var.env
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
        "kubernetes.io/role/internal-elb" = "1"
    }
}