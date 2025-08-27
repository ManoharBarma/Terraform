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
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  # Settings to optimize for LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # This is the crucial part: redirecting API calls to LocalStack 🔌
  endpoints {
    ec2    = "http://localhost:4566"
    s3     = "http://localhost:4566"
    lambda = "http://localhost:4566"
    elbv2  = "http://localhost:4566"
  }
}
