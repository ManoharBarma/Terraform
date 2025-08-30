variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the IAM role."
  type        = map(string)
  default     = {}
}

variable "allowed_secret_arn" {
  description = "The ARN of the specific secret the role is allowed to read."
  type        = string
}