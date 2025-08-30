
output "instance_id" {
  description = "The ID of the created EC2 instance."
  value       = aws_instance.this.id
}
output "private_ip" {
  description = "The private IP address of the EC2 instance."
  value       = aws_instance.this.private_ip
}