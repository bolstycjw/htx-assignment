# AWS Region for the deployment
aws_region = "ap-southeast-1"  # Change to your preferred region if needed

# VPC and subnet CIDR blocks
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# Security - Replace with your IP address for secure SSH access
ssh_allowed_ips = ["0.0.0.0/0"]  # IMPORTANT: Replace with your IP for better security
kibana_allowed_ips = ["0.0.0.0/0"]  # IMPORTANT: Restrict for better security

# EC2 instance configuration
instance_type = "t2.micro"  # Free tier eligible
key_name = "htx-assignment-key"  # Replace with your EC2 key pair name

# Storage configuration
elastic_ebs_size = 16  # Size in GB, within free tier limit

# Elasticsearch configuration
elasticsearch_version = "8.17.4"
elasticsearch_heap_size = 512  # In MB, optimized for t2.micro

# ASR API configuration
asr_memory_limit = 900  # In MB, optimized for t2.micro 