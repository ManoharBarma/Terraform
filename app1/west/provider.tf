terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
  }
}

provider "aws" {
  # Dummy values that are required by the provider
  region     = "us-west-1"
  access_key = "test"
  secret_key = "test"

  # Settings to optimize for LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # This is the crucial part: redirecting API calls to LocalStack 🔌
  endpoints {
acm            = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    elbv2          = "http://localhost:4566" # The ALB service
    iam            = "http://localhost:4566"
    rds            = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

#terraform {
#  backend "s3" {
#   bucket         = "my-enterprise-terraform-state-bucket" # Change this
#    key            = "us-west-2/terraform.tfstate"
#    region         = "us-east-1"
#  }
#}