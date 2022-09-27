terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-west-2"
}

variable vpc_cird_block {}
variable subenet_cird_block {}
variable availability_zone {}
variable env_prefix {}
variable instance_type {}
variable public_key_location {}
variable private_key_location {}
variable remote_entry_script {}

resource "aws_vpc" "my_app_vpc" {
  cidr_block = var.vpc_cird_block
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "my_app_subnet_1" {
  vpc_id = aws_vpc.my_app_vpc.id
  cidr_block = var.subenet_cird_block
  availability_zone = var.availability_zone
  tags = {
    "Name" = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_route_table" "my_app_route_table" {
  vpc_id = aws_vpc.my_app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_app_internet_gateway.id
  } 
  tags = {
    "Name" = "${var.env_prefix}-route_table"
  }
}

resource "aws_internet_gateway" "my_app_internet_gateway" {
  vpc_id = aws_vpc.my_app_vpc.id
  
  tags = {
    "Name" = "${var.env_prefix}-my_app_internet_gateway"
  }
}

resource "aws_route_table_association" "associate-rtb-subnet" {
  subnet_id = aws_subnet.my_app_subnet_1.id
  route_table_id = aws_route_table.my_app_route_table.id
}

resource "aws_security_group" "my_app_sg" {
  name = "my-app-sg"
  vpc_id = aws_vpc.my_app_vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
  }
   
  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    prefix_list_ids = []
    protocol = "-1"
    to_port = 0
  } 

  tags = {
    Name: "${var.env_prefix}-security-group"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = "${file(var.public_key_location)}"
}

resource "aws_instance" "app_server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.my_app_subnet_1.id
  vpc_security_group_ids = [ aws_security_group.my_app_sg.id ]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  # user_data = file("entry-script.sh")
  # user_data_replace_on_change = true

  provisioner "file" {
    source      = "entry-script.sh"
    destination = var.remote_entry_script
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file(var.private_key_location)}"
    host     = self.public_ip
  }

  provisioner "remote-exec" {
    script = "entry-script.sh"
  }

  provisioner "local-exec" {
    command = "echo 'Created EC2 Instance with Public IP ${self.public_ip}' "
  }

  tags = {
    Name: "${var.env_prefix}-server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}
