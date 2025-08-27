output "password_value" {
  description = "The generated password."
  value       = random_password.this.result
  sensitive   = true # Hides the password from Terraform logs
}

output "secret_arn" {
  description = "The ARN of the secret in Secrets Manager."
  value       = aws_secretsmanager_secret.this.arn
}