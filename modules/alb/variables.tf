
variable "name" {
  description = "The name for the ALB and its related resources."
  type        = string
}

variable "internal" {
  description = "A boolean flag to determine whether the ALB should be internal."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the ALB in."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to attach to the ALB."
  type        = list(string)
}

variable "security_group_ids" {
  description = "A list of security group IDs to attach to the ALB."
  type        = list(string)
}
variable "target_instances_map" {
  description = "A map of EC2 instances to attach to the target group. The keys are static names and values are the instance IDs."
  type        = map(string)
  default     = {}
}
variable "target_port" {
  description = "The port on which targets receive traffic."
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "The protocol to use for routing traffic to the targets."
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "The destination for the health check request."
  type        = string
  default     = "/"
}

variable "create_http_listener" {
  description = "Set to true to create an HTTP listener on port 80."
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to apply to the ALB."
  type        = map(string)
  default     = {}
}
