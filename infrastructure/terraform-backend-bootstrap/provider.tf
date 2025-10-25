terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Backend local volontairement (NE PAS utiliser S3 ici)
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "CryptoSentiment"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "tf-backend-bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}
