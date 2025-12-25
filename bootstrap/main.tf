provider "aws" {
  region = var.aws_region
}

# Caller identity for account-based unique bucket name
data "aws_caller_identity" "current" {}

locals {
  repo_hash   = substr(md5(path.cwd), 0, 8)
  generated_bucket_name = "tf-state-${data.aws_caller_identity.current.account_id}-${local.repo_hash}"
  bucket_name_effective = var.bucket_name != "" ? var.bucket_name : local.generated_bucket_name
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name_effective
  acl    = "private"
  # versioning configured separately with aws_s3_bucket_versioning
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Dedicated resource for server-side encryption (replacement for deprecated block)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Use dedicated resource for bucket versioning (replacement for deprecated nested block)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

/* DynamoDB state locking intentionally removed per request; using versioned S3 backend instead. */
