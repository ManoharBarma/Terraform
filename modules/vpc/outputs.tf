
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "A map of the public subnet IDs, keyed by Availability Zone."
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "A map of the private subnet IDs, keyed by Availability Zone."
  value       = { for k, v in aws_subnet.private : k => v.id }
}