# Backend Bootstrap

This folder contains Terraform that creates an S3 bucket and DynamoDB table used for remote state and locking. Run this first (in a separate account/region if desired) before initializing the main project backend.

Usage:

```bash
cd bootstrap
terraform init
# Non-interactive (preferred):
terraform apply -var 'bucket_name=app1-west-terraform-state-bucket' -var 'aws_region=us-west-1'

# Or create a terraform.tfvars in the bootstrap folder with:
# bucket_name = "app1-west-terraform-state-bucket"
# aws_region  = "us-west-1"

# Then run:
terraform apply
```

After this completes, update the root `app1` backend variables to use the created bucket and run `terraform init` in `app1` normally.
