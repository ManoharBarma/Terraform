output "secret_arn" {
  description = "The ARN of the created Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_id" {
  description = "The ID of the created secret"
  value       = aws_secretsmanager_secret.this.id
}
/* Note: raw secret values are intentionally NOT exported by this module. Read secrets at runtime by granting IAM permissions and using the Secrets Manager API. */

output "secret_string" {
  description = "The generated secret string (sensitive)."
  value       = aws_secretsmanager_secret_version.this.secret_string
  sensitive   = true
}