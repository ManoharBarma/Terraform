# Terraform Blue-Green Deployment

This repository contains Terraform configurations for a blue-green deployment setup with shared and environment-specific resources.

## Overview

- **Bootstrap**: Sets up S3 buckets for Terraform state storage.
- **Shared**: Deploys shared infrastructure (VPC, ALB, security groups) used by both blue and green environments.
- **App1**: Deploys application-specific resources (EC2, RDS) for blue and green environments using Terraform workspaces.

## Deployment Order

Follow these steps in order to deploy the infrastructure:

### 1. Bootstrap (One-time Setup)

Deploy the S3 state buckets:

```bash
cd bootstrap
terraform init
terraform apply
```

This creates the necessary S3 buckets for storing Terraform state.

### 2. Shared Resources

Deploy shared infrastructure:

```bash
cd shared
terraform init
terraform apply
```

This sets up the VPC, subnets, load balancer, and shared security groups.

### 3. Application Environments

Deploy blue and green environments for app1:

Use the interactive deploy script:

```bash
cd scripts
./interactive-deploy.sh
```

- Select `app1` as the app.
- Choose `blue` or `green` as the environment.
- Select `apply` as the action.

The script will:
- Initialize Terraform with the appropriate backend config.
- Select/create the workspace for the environment.
- Plan and apply the changes.

Alternatively, use the specific scripts:

```bash
./apply-blue.sh   # Deploys blue environment
./apply-green.sh  # Deploys green environment
```

## Traffic Switching

To switch traffic between blue and green:

1. Update the ALB listener's default action to point to the desired target group.
2. The target groups are named `app1-app-alb-tg-blue` and `app1-app-alb-tg-green`.

You can do this via the AWS console, CLI, or by updating the Terraform configuration.

## Data Replication

Database data replication between blue and green RDS instances should be handled separately using database tools (e.g., AWS DMS, logical replication).

## Cleanup

To destroy resources:

- Use the interactive script with `destroy` action.
- Or run `terraform destroy` in each directory/workspace.

**Note**: Destroy shared resources last, as they are dependencies for the app environments.

## Requirements

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- Bash shell for scripts

## Workspaces

Terraform workspaces are used to isolate blue and green environments:
- `blue`: Blue environment resources
- `green`: Green environment resources

Switch workspaces with: `terraform workspace select blue|green`