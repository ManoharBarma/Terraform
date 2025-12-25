# IAM Module

Creates an IAM role and instance profile for EC2 instances and attaches a restrictive policy to allow reading from a specific Secrets Manager secret.

Inputs:
- `role_name` (string)
- `allowed_secret_arn` (string) - ARN of the secret the role is allowed to access
- `tags` (map)

Outputs:
- `instance_profile_name` - use this to attach to EC2 instances
- `role_arn` - ARN of the created role

Example usage:
```hcl
module "ec2_iam_role" {
  source = "../modules/iam"
  role_name = "app1-ec2-role"
  allowed_secret_arn = module.db_secrets.secret_arn
}
```
