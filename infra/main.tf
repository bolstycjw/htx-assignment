terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "HTX-Assignment"
      Environment = "Development"
      Terraform   = "true"
    }
  }
}

locals {
  project_name = "htx-assignment"
} 