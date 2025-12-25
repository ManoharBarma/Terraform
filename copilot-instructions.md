Purpose
-------
This file documents clear, actionable instructions for contributors and automation (Copilot-like agents) working on this Terraform repository.

Goals
-----
- Keep the repo safe: never leak secrets in outputs or source files.
- Keep modules reusable and documented.
- Make local testing and CI reproducible and automated.
````instructions
Purpose
-------
This document provides concise, actionable guidance for contributors and automation (Copilot-like agents) working on this Terraform repository.

Goals
-----
- Keep the repository secure: never commit or output secret values.
Purpose
-------
This document provides concise, actionable guidance for contributors and automation (Copilot-like agents) working on this Terraform repository.

Goals
-----
- Keep the repository secure: never commit or output secret values.
- Produce reusable, well-documented modules.
- Make local development and deployment reproducible and simple.

High-level project model
------------------------
- The repository models a small, multi-environment setup where each app (for example `app1`) can be deployed in multiple environments (blue/green, dev, staging, prod).
- State is managed per-environment using an S3 backend with object versioning enabled to preserve state history. DynamoDB-based state locking has been removed per project policy — rely on S3 versioning and operational controls.

Repository layout (relevant parts)
---------------------------------
```
Terraform/
├─ modules/
│  ├─ vpc/
│  ├─ rds/
│  └─ ...
├─ app1/
│  ├─ backend-blue.tf       # S3 backend config for blue
│  ├─ backend-green.tf      # S3 backend config for green
│  ├─ blue.tfvars           # blue environment variables
│  ├─ green.tfvars          # green environment variables
│  └─ main.tf
├─ bootstrap/               # create S3 backend bucket (versioning enabled)
└─ copilot-instructions.md
```

Conventions
-----------
- Modules must export only non-sensitive outputs (IDs, ARNs, endpoints). If a module creates a secret, export only its ARN/ID.
- Root/environment configurations should expose a small set of top-level outputs (e.g., `application_url`, `database_endpoint`, `secret_arn`) — keep this minimal.
- Do not use Terraform workspaces in this project. Manage environments via separate backend config files (see `backend-blue.tf` / `backend-green.tf`) and environment `tfvars`.
- Parameterize environment-specific values (`aws_region`, `ami_id`, `key_name`, `s3_backend_bucket`) using variables.

Secrets handling
----------------
- Never output or commit secret values. Export only ARNs/IDs.
- Prefer application-time secret retrieval using IAM roles attached to compute resources.

Backend and bootstrap
---------------------
- Use an S3 backend with server-side encryption and object versioning enabled. Versioning preserves previous state versions and provides a simple form of state history and recovery.
- DynamoDB locking is not used in this repo per your request — be aware that without DynamoDB locks, concurrent apply operations could conflict. Use operational controls (CI gating, manual locks) to avoid concurrent applies.
- A `bootstrap/` folder is provided to create a versioned S3 bucket. The bootstrap script enables versioning on the bucket.

How to select blue vs green (no workspaces)
------------------------------------------
You choose which environment to operate by using the corresponding backend file and variables.

Examples:

Switch to blue backend and run plan/apply:
```bash
cd Terraform/app1
# copy the blue backend into place then init
cp backend-blue.tf backend.tf
terraform init
terraform plan -var-file=blue.tfvars
terraform apply -var-file=blue.tfvars
```

Switch to green:
```bash
cd Terraform/app1
cp backend-green.tf backend.tf
terraform init
terraform plan -var-file=green.tfvars
terraform apply -var-file=green.tfvars
```

If you prefer to avoid copying files, you can `-backend-config` at `terraform init` time and pass the bucket/key/region explicitly.

Module design guidelines
------------------------
- Keep module inputs small and explicit; use `validation` blocks where helpful.
- Expose stable outputs only (IDs, ARNs, endpoints). Avoid exposing resource internals.
- Each module should include a README.md showing inputs, outputs, and a minimal example.

Local testing (quick steps)
--------------------------
1. Create the S3 backend bucket using the bootstrap module (this enables versioning).
```bash
cd Terraform/bootstrap
terraform init
terraform apply -var 'bucket_name=app1-blue-terraform-state-bucket' -var 'aws_region=us-west-1'
```

2. In `Terraform/app1` select your environment (blue/green) and initialize:
```bash
cp backend-blue.tf backend.tf
terraform init
terraform plan -var-file=blue.tfvars
```

Maintenance checklist for reviewers
----------------------------------
- Confirm modules do not expose secret values.
- Confirm root/environment outputs are minimal and intentional.
- Confirm provider/backend usage is parameterized by variables and uses per-environment backend files.

Change log / intent
-------------------
When making large changes (backend, state handling, secrets behavior), add a short note here explaining intent so maintainers and automation understand the rationale.

Contact
-------
If unsure about exposing a value or default, open an issue or tag a repo maintainer for review.