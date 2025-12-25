/* Root variables are defined in app1/variables.tf - avoid redeclaring them here. */

# 1. NETWORKING - Create the VPC and Subnets
module "my_vpc" {
  source = "../modules/vpc"

  vpc_name        = "${var.app_name}-vpc"
  vpc_cidr        = "10.10.0.0/16"
  public_subnets  = { "${var.aws_region}a" = "10.10.1.0/24", "${var.aws_region}c" = "10.10.2.0/24" }
  private_subnets = { "${var.aws_region}a" = "10.10.101.0/24", "${var.aws_region}c" = "10.10.102.0/24" }
}

# 2. SECURITY - Create separate Security Groups for each layer
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

module "ec2_sg" {
  source = "../modules/sg"

  sg_name       = "${var.app_name}-ec2-sg"
  vpc_id        = module.my_vpc.vpc_id
  ingress_rules = [{ description = "Allow App traffic from ALB", from_port = 80, to_port = 80, protocol = "tcp", source_security_group_id = module.alb_sg.security_group_id }]
  egress_rules  = [{ description = "Allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}

module "rds_sg" {
  source = "../modules/sg"

  sg_name       = "${var.app_name}-rds-sg"
  vpc_id        = module.my_vpc.vpc_id
  ingress_rules = [{ description = "Allow MySQL traffic from EC2 instances", from_port = 3306, to_port = 3306, protocol = "tcp", source_security_group_id = module.ec2_sg.security_group_id }]
  egress_rules  = [{ description = "Allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}

# 3. IDENTITY - Create IAM Role for EC2 instances to access Secrets Manager
module "ec2_iam_role" {
  source             = "../modules/iam"
  role_name          = "${var.app_name}-ec2-role"
  allowed_secret_arn = module.db_secrets.secret_arn
  tags = {
    Description = "IAM Role for application EC2 instances"
  }
}

# 4. SECRETS MANAGEMENT - Create a secure, random password for the database
resource "random_id" "suffix" {
  byte_length = 4
}

module "db_secrets" {
  source      = "../modules/secrets"
  secret_name = "${var.app_name}/database/password-${random_id.suffix.hex}"
  tags        = { Description = "DB Password for the ${var.app_name}" }
}

# 5. COMPUTE - Create two EC2 instances and attach the IAM Role
locals {
  instances = {
    "server-1-ubuntu" = {
      subnet_key = "us-west-1a"
    },
    "server-2-ubuntu2" = {
      subnet_key = "us-west-1c"
    }
  }
}

module "servers" {
  for_each                  = local.instances
  create_eip                = false
  source                    = "../modules/ec2"
  instance_name             = "${var.app_name}-${each.key}"
  key_name                  = "my-aws-key"
  instance_type             = "t2.micro"
  subnet_id                 = module.my_vpc.private_subnet_ids[each.value.subnet_key]
  ami_id                    = var.ami_id
  vpc_security_group_ids    = [module.ec2_sg.security_group_id]
  iam_instance_profile_name = module.ec2_iam_role.instance_profile_name
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Welcome to ${var.app_name} - ${each.key}</h1>" > /var/www/html/index.html
              EOF
  )
}

# 6. LOAD BALANCING
module "alb" {
  source               = "../modules/alb"
  name                 = "${var.app_name}-app-alb"
  vpc_id               = module.my_vpc.vpc_id
  subnet_ids           = values(module.my_vpc.public_subnet_ids)
  security_group_ids   = [module.alb_sg.security_group_id]
  target_port          = 80
  target_instances_map = { for k, v in module.servers : k => v.instance_id }
}

# 7. DATABASE
module "db" {
  source            = "../modules/rds"
  db_name           = "${var.app_name}db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  username          = "admin"
  # For this test project we'll read the secret value using a data source.
  # In production prefer letting the application retrieve secrets at runtime.
  password               = local.db_password
  subnet_ids             = values(module.my_vpc.private_subnet_ids)
  vpc_security_group_ids = [module.rds_sg.security_group_id]
}

data "aws_secretsmanager_secret_version" "db_pw" {
  secret_id = module.db_secrets.secret_id
}

locals {
  # Secret string may be plain text or JSON; here we assume plain text password.
  db_password = try(data.aws_secretsmanager_secret_version.db_pw.secret_string, "")
}

# 8. OUTPUTS - Key information about the deployed infrastructure
output "application_url" {
  description = "The public URL to access the application. Copy this into your browser."
  value       = "http://${module.alb.alb_dns_name}"
}

output "database_endpoint" {
  description = "The connection endpoint for the RDS database instance."
  value       = module.db.db_instance_endpoint
}

output "database_password_secret_arn" {
  description = "The ARN of the secret in AWS Secrets Manager containing the database password."
  value       = module.db_secrets.secret_arn
}

output "application_server_private_ips" {
  description = "A map of the private IP addresses for the application EC2 instances."
  value       = { for k, v in module.servers : k => v.private_ip }
}

/* Removed output of raw database password for safety. The secret ARN is available above; grant roles permission and have the instances fetch the secret at runtime. */