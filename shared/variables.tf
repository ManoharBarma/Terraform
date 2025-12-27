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