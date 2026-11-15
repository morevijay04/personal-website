terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Default provider — used for S3, CloudFront, Route 53, etc.
provider "aws" {
  region = var.aws_region
}

# Alias provider locked to us-east-1.
# ACM certificates for CloudFront *must* live in us-east-1 regardless of
# where the rest of the infrastructure is deployed.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
