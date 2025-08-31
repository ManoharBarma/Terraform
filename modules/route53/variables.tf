variable "domain_name" {
  description = "The domain name for the hosted zone (e.g., example.com)."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the hosted zone."
  type        = map(string)
  default     = {}
}

variable "records" {
  description = "A list of DNS records to create in the hosted zone."
  type        = list(any)
  default     = []
}
