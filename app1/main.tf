/* Root variables are defined in app1/variables.tf - avoid redeclaring them here. */

# Usage Note: Use Terraform workspaces for blue and green environments
# Example:
# terraform workspace new blue
# terraform workspace new green
# terraform workspace select blue|green
# This ensures state isolation and avoids resource conflicts.

// Use remote state from the `shared` stack to reference shared resources
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "app1-west-terraform-state-bucket"
    key    = "state/shared/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  shared_vpc_id      = data.terraform_remote_state.shared.outputs.vpc_id
  public_subnet_ids  = values(data.terraform_remote_state.shared.outputs.public_subnet_ids)
  private_subnet_ids = values(data.terraform_remote_state.shared.outputs.private_subnet_ids)
  alb_arn            = data.terraform_remote_state.shared.outputs.alb_arn
  alb_dns_name       = data.terraform_remote_state.shared.outputs.alb_dns_name
  alb_sg_id          = data.terraform_remote_state.shared.outputs.alb_sg_id
}

# 2. SECURITY - Create separate Security Groups for each layer
module "ec2_sg" {
  source = "../modules/sg"

  sg_name       = "${var.app_name}-ec2-sg-${terraform.workspace}"
  vpc_id        = local.shared_vpc_id
  ingress_rules = [{ description = "Allow App traffic from ALB", from_port = 80, to_port = 80, protocol = "tcp", source_security_group_id = local.alb_sg_id }]
  egress_rules  = [{ description = "Allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}

module "rds_sg" {
  source = "../modules/sg"

  sg_name       = "${var.app_name}-rds-sg-${terraform.workspace}"
  vpc_id        = local.shared_vpc_id
  ingress_rules = [{ description = "Allow MySQL traffic from EC2 instances", from_port = 3306, to_port = 3306, protocol = "tcp", source_security_group_id = module.ec2_sg.security_group_id }]
  egress_rules  = [{ description = "Allow all outbound", from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }]
}

# 3. IDENTITY - Create IAM Role for EC2 instances to access Secrets Manager
module "ec2_iam_role" {
  source             = "../modules/iam"
  role_name          = "${var.app_name}-ec2-role-${terraform.workspace}"
  allowed_secret_arn = module.db_secrets.secret_arn
  tags = {
    Description = "IAM Role for application EC2 instances"
    Environment = terraform.workspace
  }
}


# 5. SECRETS MANAGEMENT - Create a secure, random password for the database
resource "random_id" "suffix" {
  byte_length = 4
}

module "db_secrets" {
  source      = "../modules/secrets"
  secret_name = "${var.app_name}/database/password-${random_id.suffix.hex}-${terraform.workspace}"
  tags        = { Description = "DB Password for the ${var.app_name}", Environment = terraform.workspace }
}



locals {
  # Prefer the immediate module output if available to avoid timing/race conditions
  db_password = module.db_secrets.secret_string
}

# 6. COMPUTE - Create two EC2 instances and attach the IAM Role
locals {
  instances = {
    "server-1-ubuntu" = {
      subnet_index = 0
    },
    "server-2-ubuntu2" = {
      subnet_index = 1
    }
  }
}

module "servers" {
  for_each                  = local.instances
  create_eip                = false
  source                    = "../modules/ec2"
  instance_name             = "${var.app_name}-${each.key}-${terraform.workspace}"
  key_name                  = "my-aws-key"
  instance_type             = "t3.micro"
  subnet_id                 = local.private_subnet_ids[each.value.subnet_index]
  ami_id                    = var.ami_id
  vpc_security_group_ids    = [module.ec2_sg.security_group_id]
  iam_instance_profile_name = module.ec2_iam_role.instance_profile_name
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Welcome to ${var.app_name} - ${each.key} - ${terraform.workspace}</h1>" > /var/www/html/index.html
              EOF
  )
}

# 6. LOAD BALANCING
resource "aws_lb_target_group" "app" {
  name     = "${var.app_name}-tg-${terraform.workspace}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.shared_vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.app_name}-tg-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = local.alb_arn
  port              = terraform.workspace == "blue" ? "80" : "81"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group_attachment" "app" {
  for_each = module.servers

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.value.instance_id
  port             = 80
}

# 7. DATABASE
module "db" {
  source                  = "../modules/rds"
  db_name                 = "${replace(var.app_name, "-", "")}"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  username                = "admin"
  # For this test project we'll read the secret value using a data source.
  # In production prefer letting the application retrieve secrets at runtime.
  password                 = local.db_password
  subnet_ids               = local.private_subnet_ids
  vpc_security_group_ids   = [module.rds_sg.security_group_id]
  backup_retention_period  = var.backup_retention_period
  skip_final_snapshot      = true
  deletion_protection      = false
}

# 8. OUTPUTS - Key information about the deployed infrastructure
output "application_url" {
  description = "The public URL to access the application. Copy this into your browser."
  value       = "http://${local.alb_dns_name}"
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