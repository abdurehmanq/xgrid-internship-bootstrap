terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Uses a stable 5.x version of the AWS provider
    }
  }
}

# Configures the AWS Provider
provider "aws" {
  region = var.aws_region
}