variable "vpc_name" {
  description = "The name of the VPC and its resources"
  type        = string
  default     = "my-app-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets: AZ -> CIDR. Must match the keys in private_subnets."
  type        = map(string)
  default = {
    "us-west-1a" = "10.0.1.0/24"
    "us-west-1b" = "10.0.2.0/24"
  }
}

variable "private_subnets" {
  description = "Map of private subnets: AZ -> CIDR. Must match the keys in public_subnets."
  type        = map(string)
  default = {
    "us-west-1a" = "10.0.101.0/24"
    "us-west-1b" = "10.0.102.0/24"
  }
}