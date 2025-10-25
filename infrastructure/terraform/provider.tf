terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # ⚠️ Backend local pour l’instant (on passera en S3+DynamoDB ensuite)
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "CryptoSentiment"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
