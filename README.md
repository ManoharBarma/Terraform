# Terraform Test Project

This repository is a small test Terraform project that provisions a simple web application stack in AWS using modular Terraform code. It demonstrates modularization, remote state bootstrapping, per-environment backends (blue/green), and practical helper scripts to make local development and testing easier.

Contents
- `app1/` — root configuration for the sample application.
- `bootstrap/` — Terraform that creates the S3 bucket used for remote state.
- `modules/` — reusable modules: `vpc`, `sg`, `ec2`, `alb`, `rds`, `secrets`, `iam`.
- `scripts/` — helper scripts for environment selection, apply convenience, formatting, and manual IAM creation.

Overview
- Architecture: VPC (public/private subnets) → EC2 application servers → ALB → RDS (MySQL) in private subnets. Secrets Manager stores the DB password and an IAM role allows EC2 to read it.
- State: remote state stored in an S3 bucket created by the `bootstrap/` module. Per-environment backends (blue/green) use `-backend-config` files.
- Environments: Blue/Green environment configurations live under `app1/` as `backend-blue.conf`, `backend-green.conf` and corresponding `blue.tfvars` / `green.tfvars`.

Quick Start
1. Prerequisites
   - Terraform >= 1.5
   - AWS CLI configured with credentials and `us-west-1` region (or edit `app1/blue.tfvars` region)
   - Optional: `jq` for some helper scripts, `ca-certificates` on WSL if you encounter SSL issues

2. Bootstrap remote state
```bash
# initialize bootstrap
terraform -chdir=bootstrap init

# Option A (recommended): create both blue and green buckets managed by bootstrap
# provide a map of buckets (or create a terraform.tfvars with `state_buckets`) and apply
terraform -chdir=bootstrap apply -var 'state_buckets={"blue"={name="app1-blue-terraform-state-bucket"},"green"={name="app1-green-terraform-state-bucket"}}' -var 'aws_region=us-west-1'

# Option B (safer if you prefer manual bucket creation): create bucket(s) manually
# then update app1/backend-<env>.conf with the created bucket name and run the per-env apply scripts.
```

3. Initialize app (per-environment scripts handle backend selection)
```bash
# For blue environment
./scripts/apply-blue.sh  # will init with backend-blue.conf and run plan/apply

# For green environment
./scripts/apply-green.sh # will init with backend-green.conf and run plan/apply
```

4. Plan & apply
```bash
terraform -chdir=app1 plan -var-file=blue.tfvars
terraform -chdir=app1 apply -var-file=blue.tfvars
```

Scripts (what each script does)

- `scripts/apply-blue.sh` and `scripts/apply-green.sh` — simplified convenience wrappers that:
  - use `app1/backend-blue.conf` / `app1/backend-green.conf` and `app1/blue.tfvars` / `app1/green.tfvars` respectively,
  - run `terraform -chdir=app1 init -backend-config=... -reconfigure`, then `plan` and `apply` with the tfvars file,
  - validate `tfvars` exists before running.

-- `scripts/manual-create-iam.sh` — helper for when Terraform IAM creation hangs.
  - Creates an IAM role, managed policy (Secrets Manager read), instance profile, attaches policy, waits for propagation, and imports them into Terraform state.
  - Usage: `./scripts/manual-create-iam.sh --app app1-blue --region us-west-1 --secret-arn <SECRET_ARN>`
  - Useful for debugging provider hangs; the script attempts to find a secret automatically if `--secret-arn` is omitted.

- `scripts/format.sh` — runs `terraform fmt -recursive` across the repository.

Files of interest
- `app1/main.tf` — wires modules: `vpc`, `sg`, `ec2`, `alb`, `rds`, `secrets`, `iam`.
- `bootstrap/main.tf` — creates S3 bucket and associated resources for remote state (SSE, versioning).
- `modules/iam/main.tf` — defines the EC2 role, `aws_iam_policy`, and the instance profile.
- `modules/rds/variables.tf` — controls parameters such as `backup_retention_period` (set to 0 in `app1/*.tfvars` for free-tier accounts).

Blue/Green state workflow
- Use `backend-*.conf` files with `terraform init -backend-config=...`. Avoid committing `backend.tf` with backend blocks to prevent duplicate backend errors.
- Two supported workflows:
  - Let `bootstrap` manage both buckets: update `bootstrap` `state_buckets` (or run the `apply` with `-var 'state_buckets=...'`) to create both `blue` and `green` buckets. After migrating any legacy bootstrap state into the `blue` map key (see `bootstrap/README.md`) you can create `green` safely without destroying `blue`.
  - Or create green manually (AWS CLI/console) and update `app1/backend-green.conf` to point to that bucket. This avoids changing bootstrap state.
- `apply-*.sh` scripts are the recommended way to initialize and apply each environment since they pass the correct backend-config and var-file automatically.

Troubleshooting
- Duplicate backend block: remove extra `terraform { backend "s3" { ... } }` blocks from `.tf` files; use `-backend-config` files instead.
- RDS Free Tier error: if you see `FreeTierRestrictionError`, set `backup_retention_period = 0` in your environment tfvars or upgrade the account.
- AWS CLI SSL errors on WSL: install CA certs `sudo apt-get install -y ca-certificates`, run `sudo update-ca-certificates`, and ensure system time is correct.
- Provider hang during resource creation: run targeted create with debug logs: `TF_LOG=DEBUG TF_LOG_PATH=./tf-debug.log terraform -chdir=app1 apply -target=module.ec2_iam_role -var-file=blue.tfvars` and review `tf-debug.log`.
- If IAM creation hangs, use `scripts/manual-create-iam.sh` to manually create and import the resources.

State & concurrency
- DynamoDB locking was removed by request. For production, create a DynamoDB table and enable locking to avoid concurrent `terraform apply` collisions.

Security notes
- Do not output raw secret values. The secrets module exposes `secret_arn` and `secret_id` only. Applications should fetch secrets at runtime using the EC2 IAM role.

Next steps & recommended improvements
- Add `tflint` and `tfsec` in CI for code quality/security scanning.
- Add a small `Makefile` or `Makefile` targets to standardize init/plan/apply flows.
- Consider enabling DynamoDB locking for production state safety.

Contact
- If you want me to add a `DOCS.md` with diagrams or generate a `graph.png` of the dependency graph, I can do that next.
