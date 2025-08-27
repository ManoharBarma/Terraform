variable "secret_name" {
  description = "The name/path for the secret in AWS Secrets Manager."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the secret."
  type        = map(string)
  default     = {}
}