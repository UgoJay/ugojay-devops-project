provider "aws" {
  region = "us-east-1"
}

# Dynamic Lookups: Ask AWS for the latest official Ubuntu 24.04 LTS Image
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Official Canonical Owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Isolated Project Network
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "devops-school-vpc" }
}

# 2. Public Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_vpc.id
  tags   = { Name = "devops-gateway" }
}

# 3. Public Subnet Block
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags                    = { Name = "devops-public-subnet" }
}

# 4. Routing Infrastructure
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "devops-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. Security Group (Cloud Firewall Rules)
resource "aws_security_group" "devops_sg" {
  name        = "devops-firewall-rules"
  description = "Pipeline control and application web access"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    description = "SSH Access for Deployment"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Portfolio UI Web Interface"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Java Microservice Engine"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "devops-security-group" }
}

# 6. EC2 Server Provisioning
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.latest_ubuntu.id # Dynamically pulls the clean verified ID
  instance_type          = "t2.micro"                    # 100% Free Tier Eligible
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  key_name               = "Ugo-demo-key"          # Key pair name from your AWS console

  tags = { Name = "devops-production-target" }
}

# 7. Output Result values
output "target_server_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The target deployment IP address for Ansible configuration"
}
