terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
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
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "securecloud-sentinel"

  default_tags {
    tags = {
      Project     = "SecureCloud Sentinel"
      ManagedBy   = "Terraform"
      Environment = "lab"
    }
  }
}