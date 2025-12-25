variable "aws_region" {
  description = "AWS region to create backend resources in"
  type        = string
  default     = "us-west-1"
}

variable "bucket_name" {
  description = "S3 bucket name to use for Terraform state. If empty, a name will be generated using account id + repo hash."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
