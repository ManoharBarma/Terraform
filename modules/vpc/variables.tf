# --- Variable Definitions ---

variable "vpc_name" {
  description = "The name tag for the VPC and its resources."
  type        = string
  default     = "my-app-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A map of public subnets, pairing availability zones with CIDR blocks."
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
  }
}

variable "private_subnets" {
  description = "A map of private subnets, pairing availability zones with CIDR blocks."
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.101.0/24"
    "us-east-1b" = "10.0.102.0/24"
  }
}
