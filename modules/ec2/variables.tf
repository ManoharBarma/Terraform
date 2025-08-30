
variable "instance_name" {
  description = "The name tag for the EC2 instance."
  type        = string
}

variable "ami_id" {
  description = "The ID of the Amazon Machine Image (AMI) to use for the instance."
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start (e.g., 't2.micro')."
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for the instance."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance into."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with the instance."
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "User data to provide when launching the instance."
  type        = string
  default     = null
}

variable "create_eip" {
  description = "Set to true to create and associate an Elastic IP."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of additional tags to apply to the instance."
  type        = map(string)
  default     = {}
}
variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile to associate with the instance."
  type        = string
  default     = null
}