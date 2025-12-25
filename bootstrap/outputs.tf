output "s3_bucket_id" {
  description = "ID of the created S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_name" {
  description = "Name of the created S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}


