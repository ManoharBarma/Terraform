output "s3_bucket_ids" {
  description = "Map of S3 bucket IDs keyed by environment (e.g., blue/green)"
  value       = { for k, v in aws_s3_bucket.terraform_state : k => v.id }
}

output "s3_bucket_names" {
  description = "Map of S3 bucket names keyed by environment (e.g., blue/green)"
  value       = { for k, v in aws_s3_bucket.terraform_state : k => v.bucket }
}