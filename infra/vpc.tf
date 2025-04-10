# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.project_name}-public-subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Elastic IPs for EC2 instances
resource "aws_eip" "elastic_stack" {
  domain = "vpc"
  tags = {
    Name = "${local.project_name}-elastic-eip"
  }
}

resource "aws_eip" "services" {
  domain = "vpc"
  tags = {
    Name = "${local.project_name}-services-eip"
  }
}

resource "aws_eip" "asr" {
  domain = "vpc"
  tags = {
    Name = "${local.project_name}-asr-eip"
  }
}

# EIP Association
resource "aws_eip_association" "elastic_stack" {
  instance_id   = aws_instance.elastic_stack.id
  allocation_id = aws_eip.elastic_stack.id
}

resource "aws_eip_association" "services" {
  instance_id   = aws_instance.services.id
  allocation_id = aws_eip.services.id
}

resource "aws_eip_association" "asr" {
  instance_id   = aws_instance.asr.id
  allocation_id = aws_eip.asr.id
} 