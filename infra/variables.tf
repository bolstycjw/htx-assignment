variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_ips" {
  description = "List of IPs allowed to SSH into EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # For production, restrict this to your IP
}

variable "kibana_allowed_ips" {
  description = "List of IPs allowed to access Kibana"
  type        = list(string)
  default     = ["0.0.0.0/0"] # For production, restrict this to specific IPs
}

variable "elasticsearch_allowed_ips" {
  description = "List of IPs allowed to access Elasticsearch API"
  type        = list(string)
  default     = ["0.0.0.0/0"] # For production, restrict this to specific IPs
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "elastic_ebs_size" {
  description = "Size of EBS volume for Elasticsearch in GB"
  type        = number
  default     = 16
}

variable "key_name" {
  description = "Name of the EC2 key pair to use"
  type        = string
  default     = null # Provide your key pair name or create a new one
}

variable "elasticsearch_version" {
  description = "Version of Elasticsearch to use"
  type        = string
  default     = "8.17.4"
}

variable "elasticsearch_heap_size" {
  description = "Elasticsearch heap size in MB"
  type        = number
  default     = 512
}

variable "asr_memory_limit" {
  description = "Memory limit for ASR container in MB"
  type        = number
  default     = 900
} 