resource "aws_subnet" "my_app_subnet_1" {
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cird_block
  availability_zone = var.availability_zone
  tags = {
    "Name" = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_route_table" "my_app_route_table" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_app_internet_gateway.id
  } 
  tags = {
    "Name" = "${var.env_prefix}-route_table"
  }
}

resource "aws_internet_gateway" "my_app_internet_gateway" {
  vpc_id = var.vpc_id
  
  tags = {
    "Name" = "${var.env_prefix}-my_app_internet_gateway"
  }
}
  
resource "aws_route_table_association" "associate-rtb-subnet" {
  subnet_id = aws_subnet.my_app_subnet_1.id
  route_table_id = aws_route_table.my_app_route_table.id
}