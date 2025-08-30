terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

terraform {
  backend "s3" {
    bucket = "app1-west-terraform-state-bucket"
    key    = "app1/terraform.tfstate"
    region = "us-west-1"
  }
}
