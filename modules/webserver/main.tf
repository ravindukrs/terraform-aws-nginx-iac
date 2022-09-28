resource "aws_security_group" "my_app_sg" {
  name = "my-app-sg"
  vpc_id = var.vpc_id

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
  subnet_id = var.subnet_id
  vpc_security_group_ids = [ aws_security_group.my_app_sg.id ]
  availability_zone = var.availability_zone
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name


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
