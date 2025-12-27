# Copilot Instructions: Terraform Blue/Green POC

This repository is a proof-of-concept (POC) Terraform codebase that demonstrates a blue/green deployment pattern with shared networking and load-balancing and per-environment compute and databases. The intent is to provide a minimal, reproducible setup for testing deployment workflows (switching traffic between blue and green), workspace-based state separation, and safe state handling.

Purpose & Goals

- Demonstrate blue/green deployment using Terraform workspaces (`blue` and `green`).
- Share expensive infra (VPC, ALB, security groups) between environments while keeping compute and databases separate per environment.
- Use separate RDS instances per environment (no shared DB) to allow independent testing and failover.
- Provide a bootstrap step to create S3 state buckets for each app/environment.
- Offer simple scripts to initialize, plan, and apply each environment.

High-level Architecture

- `bootstrap/`: Creates S3 buckets used as Terraform backends (per-app and per-environment keys). This module also creates optional DynamoDB lock tables if configured.
- `shared/`: Creates shared resources — VPC, public/private subnets, NAT gateways, ALB, ALB security group.
- `app1/`: Application-specific stack that creates EC2 instances (two per environment), per-environment RDS, security groups, and ALB target groups/listeners for blue/green traffic routing. Other apps can be added by copying the same pattern.
- `modules/`: Reusable modules: `vpc`, `alb`, `sg`, `ec2`, `rds`, `iam`, `secrets`, etc.

Important Constraints & Decisions

- Workspaces: Use Terraform workspaces to isolate `blue` and `green` state for each app. Backend keys include workspace names to keep states separate.
- State Management: `bootstrap` creates per-app buckets and keys. The POC allows destructive operations (no `prevent_destroy`), but in production you should enable bucket protections and backups before making destructive changes.
- Remote State Access: App stacks read shared outputs via `data.terraform_remote_state` to reliably reference VPC/ALB resources.
- Naming: Resources use `${var.app_name}` and `${terraform.workspace}` to avoid collisions and to make environment switching predictable.

What Copilot Should Know When Assisting

- This repo is a POC: speed and clarity are preferred over production-grade hardening. The user intentionally allows destructive operations for quick iteration.
- The expected workflow for adding or modifying infra is:
  1. Run `bootstrap` to ensure S3 backends exist.
  2. Apply `shared` to create the VPC/ALB.
  3. For each app, initialize the backend with the correct `backend-<workspace>.conf`, select or create the workspace (`blue`/`green`), and `apply` the environment-specific var file (e.g., `blue.tfvars`).
- When Copilot modifies Terraform files:
  - Avoid changing backend naming conventions unless the user asks.
  - Prefer non-destructive fixes (imports, state rm) when reconciling with existing infrastructure unless the user explicitly requests destruction.
  - Keep changes minimal and consistent with existing naming patterns.
- If a `data` source lookup repeatedly fails (resource not yet created), prefer adding a `terraform_remote_state` data block or guide the order of operations instead of introducing brittle filters.

Operational Tips for Users

- Use the included scripts in `scripts/` for interactive workspace creation and deployment. Adjust `backend-*.conf` files to match your S3 bucket names if you fork this repo.
- On Windows, run Terraform from PowerShell with one command per line (avoid `||` chains), or use the `-chdir` flag carefully — PowerShell sometimes treats `||` as invalid.
- If Terraform reports `BucketAlreadyOwnedByYou` during bootstrap, import that bucket into the bootstrap state or remove the conflicting entry from state:
  - `terraform state rm 'aws_s3_bucket.terraform_state["<key>"]'`
  - or import: `terraform import 'aws_s3_bucket.terraform_state["<key>"]' <bucket-name>`
- To add a second app (`app2`): duplicate the `app1` directory, update `app_name` and backend configs, add the app to `bootstrap/vars` if you want dedicated state buckets, then follow the same bootstrap → shared → app apply order.

Suggested Copilot Behaviors (explicit guidance)

- When asked to run commands: always provide the exact, one-line shell commands for the user's OS. For PowerShell, avoid using `||` or chaining operators that may not be supported.
- When editing Terraform: prefer `terraform_remote_state` to data lookups across stacks; ensure outputs are present in the target stack before relying on them.
- When making large or destructive changes: always ask for explicit confirmation (or detect the user's explicit consent in prior messages) before running `terraform destroy` or removing state.
- When automation fails due to environment issues (missing AWS CLI, interrupted terminal), explain the likely root cause and provide a minimal set of manual commands the user can run locally.

What to include in PR descriptions

- Short summary of the change (1–2 lines).
- Files changed and the reason (e.g., "use terraform_remote_state for shared outputs to avoid race conditions").
- Any required manual steps for deployment or state migration (e.g., import commands or backend reconfigure).
- Risk statement (destructive vs non-destructive) and recommended rollback/backups.

Contact and escalation

- If Copilot cannot complete a destructive operation due to environment instability, it should stop and ask the user to either run the provided script locally or give permission to continue.

---

Add this file at the repository root as `copilot-instructions.md`. If you'd like I can also add a short `README-PROD.md` that lists production hardening steps (versioning, IAM lockdown, bucket policies, non-destructive lifecycle rules, backups).