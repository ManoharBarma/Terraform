variable "vpc_name" {
  description = "The name of the VPC and its resources"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets: AZ -> CIDR. Must match the keys in private_subnets."
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of private subnets: AZ -> CIDR. Must match the keys in public_subnets."
  type        = map(string)
}