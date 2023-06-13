# Configure the AWS Provider

provider "aws" {
  region = "us-east-1"
  access_key = "AKIAY2CD7GACH2X64X5L"
  secret_key = "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"
}

# resource "aws_instance" "server-1" {
#     ami = "ami-053b0d53c279acc90"
#     instance_type = "t2.micro"
#     tags = {
#     #   Name = "ubuntu"
#     }
  
# }

# Create a VPC
# resource "aws_vpc" "first-vpc" {
#   cidr_block = "10.0.0.0/16"
#     tags = {
#         Name = "testing"
#     }
# }

# create subnet
# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.first-vpc.id 
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "test-subnet"
#   }
# }

# resource "<providers>_<resource_types>" "name" {
    # config options
    # key = "value"
    # key2 = "another value"
# }

#############################################################################################################################

# Terrafrom assignment

# 1. Create vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

}

# 3. Custom route table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create a Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Prod-subnet"
  }
  
}

# 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create a security group to allow port 22,80,443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web-traffic inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "HTTPS"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step  4

resource "aws_network_interface" "web-server-ppp" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}

# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-ppp.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.gw ]
}

output "server_public_ip" {
  value = aws_eip.one.public_ip
  
}

# 9. Create ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-ppp.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo your very first web server > /var/www/html/index.html"
              EOF
  
  tags = {
    Name = "web-server"
  }
  
}

output "server_private_ip" {
  value = aws_instance.web-server-instance.private_ip
  
}

output "server_id" {
  value = aws_instance.web-server-instance.id
  
}
