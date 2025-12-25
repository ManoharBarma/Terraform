# Backend bootstrap (simple guide)

This folder creates an S3 bucket and a DynamoDB table for Terraform remote state and state locking. Run this first (can be in a separate account/region) before initializing the main project backends.

Prerequisites:
- Terraform installed
- AWS credentials configured (environment vars, shared credentials, or IAM role)

Quick start:

1. Change into the bootstrap folder and initialize:

```bash
cd bootstrap
terraform init
```

2. Create the backend resources. Option A (provide a bucket name you control):

```bash
terraform apply -auto-approve -var 'bucket_name=your-unique-bucket-name' -var 'aws_region=us-west-1'
```

Option B (let Terraform generate a unique bucket name):

```bash
terraform apply -auto-approve -var 'aws_region=us-west-1'
terraform output -raw s3_bucket_name
```

What to do next:
- Note the created S3 bucket name and DynamoDB table (outputs include them).
- Update your app1 backend config (for example `app1/backend-green.conf` or `app1/backend-blue.conf`) with the bucket name and a unique `key` (e.g. `green/terraform.tfstate`).
- In the app1 folder, run `terraform init` to enable remote state.

Notes:
- Use unique `key` paths per environment to avoid collisions (blue vs green).
- The DynamoDB table created here is used for state locking — keep it.

That's it — the bootstrap step provisions the remote state infrastructure so the main Terraform project can use remote state safely.
