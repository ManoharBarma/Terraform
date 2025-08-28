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

}

terraform {
  backend "s3" {
    bucket = "app1-west-terraform-state-bucket"
    key    = "app1/terraform.tfstate"
    region = "us-west-1"
  }
}
