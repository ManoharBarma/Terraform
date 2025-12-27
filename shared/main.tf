/* Shared resources for blue-green deployment */

terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

# 1. NETWORKING - Create the VPC and Subnets
module "my_vpc" {
  source = "../modules/vpc"

  vpc_name        = "${var.app_name}-vpc"
  vpc_cidr        = "10.10.0.0/16"
  public_subnets  = { "${var.aws_region}a" = "10.10.1.0/24", "${var.aws_region}c" = "10.10.2.0/24" }
  private_subnets = { "${var.aws_region}a" = "10.10.101.0/24", "${var.aws_region}c" = "10.10.102.0/24" }
}

# 2. SECURITY - Create ALB Security Group
module "alb_sg" {
  source = "../modules/sg"

  sg_name = "${var.app_name}-alb-sg"
  vpc_id  = module.my_vpc.vpc_id
  ingress_rules = [
    { description = "Allow HTTP from anywhere", from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { description = "Allow HTTPS from anywhere", from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
  egress_rules = [{ description = "Allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}

# 3. LOAD BALANCER
module "alb" {
  source               = "../modules/alb"
  name                 = "${var.app_name}-app-alb"
  vpc_id               = module.my_vpc.vpc_id
  subnet_ids           = values(module.my_vpc.public_subnet_ids)
  security_group_ids   = [module.alb_sg.security_group_id]
  target_port          = 80
  target_instances_map = {}  # No instances here, TGs will be created in ${var.app_name}
  create_tg            = false
  create_http_listener = false
}

# Outputs
output "vpc_id" {
  value = module.my_vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.my_vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.my_vpc.private_subnet_ids
}

output "alb_sg_id" {
  value = module.alb_sg.security_group_id
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}