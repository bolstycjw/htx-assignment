# Security Groups

# SSH Security Group
resource "aws_security_group" "ssh" {
  name        = "${local.project_name}-ssh-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from specified IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-ssh-sg"
  }
}

# Elasticsearch Security Group
resource "aws_security_group" "elasticsearch" {
  name        = "${local.project_name}-es-sg"
  description = "Allow Elasticsearch inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Elasticsearch port from VPC"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = var.elasticsearch_allowed_ips
  }

  ingress {
    description = "Elasticsearch port for node communication"
    from_port   = 9300
    to_port     = 9300
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-es-sg"
  }
}

# Kibana Security Group
resource "aws_security_group" "kibana" {
  name        = "${local.project_name}-kibana-sg"
  description = "Allow Kibana inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kibana port"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = var.kibana_allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-kibana-sg"
  }
}

# ASR API Security Group
resource "aws_security_group" "asr" {
  name        = "${local.project_name}-asr-sg"
  description = "Allow ASR API inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ASR API port"
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-asr-sg"
  }
}

# Search UI Security Group
resource "aws_security_group" "ui" {
  name        = "${local.project_name}-ui-sg"
  description = "Allow Search UI inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Search UI port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-ui-sg"
  }
}

# Docker Network Security Group
resource "aws_security_group" "docker_network" {
  name        = "${local.project_name}-docker-network-sg"
  description = "Allow all traffic within the Docker network"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-docker-network-sg"
  }
}

# IAM Role for CloudWatch monitoring
resource "aws_iam_role" "ec2_cloudwatch" {
  name = "${local.project_name}-ec2-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${local.project_name}-ec2-cloudwatch"
  }
}

# Attach CloudWatch agent policy to the IAM role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create instance profile for the IAM role
resource "aws_iam_instance_profile" "ec2_cloudwatch" {
  name = "${local.project_name}-ec2-cloudwatch"
  role = aws_iam_role.ec2_cloudwatch.name
} 