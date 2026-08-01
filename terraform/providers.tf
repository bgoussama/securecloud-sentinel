terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-3"
  profile = "securecloud-sentinel"

  default_tags {
    tags = {
      Project     = "SecureCloud Sentinel"
      ManagedBy   = "Terraform"
      Environment = "lab"
    }
  }
}