
variable "db_name" {
  description = "The name of the database to create."
  type        = string
}

variable "engine" {
  description = "The database engine to use (e.g., 'mysql', 'postgres')."
  type        = string
}

variable "engine_version" {
  description = "The engine version to use."
  type        = string
}

variable "instance_class" {
  description = "The instance class for the RDS instance (e.g., 'db.t3.micro')."
  type        = string
}

variable "allocated_storage" {
  description = "The initial allocated storage in GB."
  type        = number
}

variable "max_allocated_storage" {
  description = "The maximum storage to allow for autoscaling in GB."
  type        = number
  default     = 100
}

variable "username" {
  description = "The master username for the database."
  type        = string
}

variable "password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true # Marks the password as sensitive in Terraform outputs
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "A list of VPC security group IDs to associate with the DB instance."
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the DB instance is publicly accessible."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to apply to the RDS instance."
  type        = map(string)
  default     = {}
}
