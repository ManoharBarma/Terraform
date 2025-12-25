
variable "sg_name" {
  description = "The name of the security group."
  type        = string
}

variable "sg_description" {
  description = "The description of the security group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the security group."
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "A list of objects representing ingress (inbound) rules."
  type        = list(any)
  default     = []
}

variable "egress_rules" {
  description = "A list of objects representing egress (outbound) rules."
  type        = list(any)
  default     = []
}

