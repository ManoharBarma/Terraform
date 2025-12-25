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

variable "state_buckets" {
  description = "Map of backend state buckets to create, keyed by environment name. If empty, the single legacy bucket_name will be used as 'blue'."
  type = map(object({
    name = string
  }))
  default = {
    blue  = { name = "app1-blue-terraform-state-bucket" }
    green = { name = "app1-green-terraform-state-bucket" }
  }
}
