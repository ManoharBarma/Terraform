provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
locals {
  repo_hash = substr(md5(path.cwd), 0, 8)

  # legacy fallback name when bucket_name is provided but state_buckets is empty
  legacy_bucket_name = var.bucket_name != "" ? var.bucket_name : "tf-state-${data.aws_caller_identity.current.account_id}-${local.repo_hash}"

  # Buckets for apps: shared, blue, green per app
  app_buckets = merge(flatten([
    for app in var.apps : {
      "${app}-shared" = { name = "${app}-west-terraform-state-bucket" }
      "${app}-blue"   = { name = "${app}-blue-terraform-state-bucket" }
      "${app}-green"  = { name = "${app}-green-terraform-state-bucket" }
    }
  ])...)

  # effective map of buckets: app buckets + provided state_buckets or legacy
  state_buckets_effective = merge(
    local.app_buckets,
    length(var.state_buckets) > 0 ? var.state_buckets : {
      blue = { name = local.legacy_bucket_name }
    }
  )
}

resource "aws_s3_bucket" "terraform_state" {
  for_each = local.state_buckets_effective

  bucket = each.value.name
  tags   = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.terraform_state
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.terraform_state
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning for state buckets
resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.terraform_state
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}
