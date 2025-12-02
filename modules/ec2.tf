
# The main key for both jump server and node groups
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Key Pair for Jump Server and EKS Nodes
resource "aws_key_pair" "main-key" {
  key_name = "${var.env}-main-key"
  public_key = tls_private_key.rsa_key.public_key_openssh
}

# Saving the private key in the local machine
resource "local_file" "main-key-private-key" {
  content = tls_private_key.rsa_key.private_key_pem
  filename = "id_rsa_key"
  provisioner "local-exec" {
    command = "chmod 600 id_rsa_key"
  }
}

# The Jump Server EC2 Instance
resource "aws_instance" "Jump-Server" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.main-key.key_name
  subnet_id     = aws_subnet.public-subnets[0].id
  vpc_security_group_ids = [ aws_security_group.jump-server-sg.id ]
  associate_public_ip_address = true 

  root_block_device {
   volume_size = var.jump_server_disk_size
   volume_type = "gp3"
  } 

  user_data = file("${path.root}/script.sh")

  tags = {
    Name = "${var.env}-jump-server"
  }
}