variable "app_name" {
  description = "The name of the application."
  type        = string
  default     = "app1-west"
}

# 1. NETWORKING - Create the VPC and Subnets

module "my_vpc" {
  source          = "../../modules/vpc"
  vpc_name        = "${var.app_name}-vpc"
  vpc_cidr        = "10.10.0.0/16"
  public_subnets  = { "us-west-1a" = "10.10.1.0/24" }
  private_subnets = { "us-west-1a" = "10.10.101.0/24" }
}

# 2. SECURITY - Create separate Security Groups for each layer

# --- Security Group for the public-facing Application Load Balancer ---
module "alb_sg" {
  source  = "../../modules/sg"
  sg_name = "${var.app_name}-alb-sg"
  vpc_id  = module.my_vpc.vpc_id
  ingress_rules = [
    { description = "Allow HTTP from anywhere",
      from_port   = 80,
      to_port     = 80,
      protocol    = "tcp",
    cidr_blocks = ["0.0.0.0/0"] },
    { description = "Allow HTTPS from anywhere",
      from_port   = 443,
      to_port     = 443,
      protocol    = "tcp",
    cidr_blocks = ["0.0.0.0/0"] }
  ]
  egress_rules = [
    { description = "Allow all outbound",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
    cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# --- Security Group for the private EC2 instances ---
module "ec2_sg" {
  source  = "../../modules/sg"
  sg_name = "${var.app_name}-ec2-sg"
  vpc_id  = module.my_vpc.vpc_id
  ingress_rules = [
    { description = "Allow App traffic from ALB",
      from_port   = 8080,
      to_port     = 8080,
      protocol    = "tcp",
    source_security_group_id = module.alb_sg.security_group_id }
  ]
  egress_rules = [
    { description = "Allow all outbound",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
    cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# --- Security Group for the RDS Database ---
module "rds_sg" {
  source  = "../../modules/sg"
  sg_name = "${var.app_name}-rds-sg"
  vpc_id  = module.my_vpc.vpc_id

  ingress_rules = [
    {
      description              = "Allow MySQL traffic from EC2 instances"
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.ec2_sg.security_group_id
    }
  ]
  egress_rules = [
    { description = "Allow all outbound",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
    cidr_blocks = ["0.0.0.0/0"] }
  ]
}

# 3. SECRETS MANAGEMENT - Call the new secrets module

module "db_secrets" {
  source      = "../../modules/secrets"
  secret_name = "${var.app_name}/database/password"
  tags = {
    Description = "Password for the main production database"
  }
}

# 4. COMPUTE - Create two EC2 instances using the EC2 module
locals {
  instances = {
    "server-1-ubuntu" = {
      instance_type = "t2.medium"
      ami_id        = "ami-0c55b159cbfafe1f0" # <-- Ubuntu AMI
      user_data     = <<-EOF
              #!/bin/bash
              # Commands for Ubuntu (apt-get)
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Hello from Ubuntu Server 1</h1>" > /var/www/html/index.html
              EOF
    },
    "server-2-amazon-linux" = {
      instance_type = "t2.micro"
      ami_id        = "ami-0c55b159cbfafe1f0" # <-- Original Amazon Linux AMI
      user_data     = <<-EOF
              #!/bin/bash
              # Commands for Amazon Linux (yum)
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Amazon Linux Server 2</h1>" > /var/www/html/index.html
              EOF
    }
  }
}
module "servers" {
  for_each               = local.instances
  source                 = "../../modules/ec2"
  instance_name          = "${var.app_name}-${each.key}"
  key_name               = "my-aws-key"
  instance_type          = each.value.instance_type
  subnet_id              = module.my_vpc.private_subnet_ids[0]
  user_data              = each.value.user_data # can also use file directly --> file("${path.module}/../user_data.sh")
  ami_id                 = each.value.ami_id
  vpc_security_group_ids = [module.ec2_sg.security_group_id]
}

# 5. LOAD BALANCING - Create the ALB and attach the EC2 instances

module "alb" {
  source = "../../modules/alb"
  name               = "${var.app_name}-app-alb"
  vpc_id             = module.my_vpc.vpc_id
  subnet_ids         = module.my_vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]
  target_port        = 8080 # Make sure this matches your EC2 SG port
  target_instances_map = { for k, v in module.servers : k => v.instance_id }
}

# 6. DATABASE - Create the RDS instance

module "db" {
  source = "../../modules/rds"
  db_name                = "${var.app_name}-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = module.db_secrets.password_value
  subnet_ids             = module.my_vpc.private_subnet_ids
  vpc_security_group_ids = [module.rds_sg.security_group_id]
}

# 7. OUTPUTS - Add this to your existing outputs

output "alb_zone_id" {
  description = "The Route 53 zone ID of the application load balancer."
  value       = module.alb.alb_zone_id
}