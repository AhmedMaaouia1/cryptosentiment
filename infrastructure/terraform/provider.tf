terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "cryptosentiment-tfstates-834473887114"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "cryptosentiment-tf-locks"
    encrypt        = true
  }
}
