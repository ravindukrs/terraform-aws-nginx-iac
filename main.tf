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

resource "aws_vpc" "my_app_vpc" {
  cidr_block = var.vpc_cird_block
  tags = {
    "Name" = "${var.env_prefix}-vpc"
  }
}

module "my_app_subnet" {
  source = "./modules/subnet"
  subnet_cird_block = var.subnet_cird_block
  availability_zone = var.availability_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.my_app_vpc.id
}

module "my_app_server" {
  source = "./modules/webserver"
  vpc_id = aws_vpc.my_app_vpc.id
  subnet_id = module.my_app_subnet.subnet.id
  env_prefix = var.env_prefix
  public_key_location = var.public_key_location
  private_key_location = var.private_key_location
  remote_entry_script = var.remote_entry_script
  availability_zone = var.availability_zone
  instance_type = var.instance_type
}
