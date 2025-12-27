variable "app_name" {
  description = "The name of the application used for naming and tags."
  type        = string
  default     = "app1"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-1"
}

variable "s3_backend_bucket" {
  description = "S3 bucket name to store Terraform state."
  type        = string
  default     = "app1-west-terraform-state-bucket"
}

variable "dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking (optional)."
  type        = string
  default     = "app1-terraform-locks"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances."
  type        = string
  default     = "ami-00271c85bf8a52b84"
}

variable "key_name" {
  description = "SSH key pair name for EC2 access (optional)."
  type        = string
  default     = "my-aws-key"
}

variable "create_eip" {
  description = "Whether to create Elastic IPs for instances."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for the RDS instance."
  type        = number
  default     = 0
}
