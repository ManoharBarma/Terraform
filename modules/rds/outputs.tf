output "db_instance_endpoint" {
  description = "The connection endpoint for the database instance."
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "The address of the database instance."
  value       = aws_db_instance.this.address
}

output "db_instance_arn" {
  description = "The ARN of the database instance."
  value       = aws_db_instance.this.arn
}

output "db_instance_id" {
  description = "The ID of the database instance."
  value       = aws_db_instance.this.id
}