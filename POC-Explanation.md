# Terraform Blue-Green Deployment POC

This repository demonstrates a complete Infrastructure as Code (IaC) setup for blue-green deployments using Terraform, featuring environment isolation, shared resources, and scalable application stacks.

## Architecture Overview

The POC implements a multi-layered infrastructure architecture:

```
┌─────────────────┐    ┌─────────────────┐
│   Bootstrap     │    │   Workspaces    │
│                 │    │                 │
│ • S3 Buckets    │    │ • Blue Env      │
│ • DynamoDB      │    │ • Green Env     │
│ • State Mgmt    │    │ • Isolation     │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
                 │
        ┌─────────────────┐
        │  Shared Layer   │
        │                 │
        │ • VPC           │
        │ • Subnets       │
        │ • ALB           │
        │ • Security Grps │
        └─────────────────┘
                 │
        ┌─────────────────┐
        │   App Layer     │
        │                 │
        │ • EC2 Instances │
        │ • RDS Database  │
        │ • Auto Scaling  │
        │ • Load Balancing│
        └─────────────────┘
```

## Directory Structure

```
Terraform/
├── bootstrap/           # Initial infrastructure setup
│   ├── main.tf         # S3 buckets, DynamoDB tables
│   ├── variables.tf    # Bootstrap configuration
│   └── outputs.tf      # Bucket names, table names
├── shared/             # Shared infrastructure
│   ├── main.tf         # VPC, ALB, Security Groups
│   ├── variables.tf    # Shared resource config
│   └── outputs.tf      # Resource IDs for apps
├── app1/               # Application environments
│   ├── main.tf         # EC2, RDS, app-specific resources
│   ├── variables.tf    # App configuration
│   ├── blue.tfvars     # Blue environment overrides
│   ├── green.tfvars    # Green environment overrides
│   ├── backend-blue.conf   # Blue state backend
│   └── backend-green.conf   # Green state backend
└── scripts/            # Automation scripts
    ├── apply-blue.sh      # Deploy blue environment
    ├── apply-green.sh     # Deploy green environment
    ├── interactive-deploy.sh  # Interactive deployment
    └── teardown.sh         # Destroy all environments
```

## Deployment Flow

### 1. Bootstrap Phase

The bootstrap phase creates the foundational infrastructure that supports all subsequent deployments:

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

**What it creates:**
- S3 buckets for Terraform state storage (one per environment)
- DynamoDB tables for state locking
- IAM policies and roles for cross-account access (if needed)

**Why separate?** Bootstrap resources are long-lived and rarely change. They provide the state management backbone for all environments.

### 2. Shared Resources Phase

The shared layer contains infrastructure components that are common across all application environments:

```bash
cd shared
terraform init -backend-config=backend.conf
terraform plan
terraform apply
```

**What it creates:**
- VPC with public/private subnets across multiple AZs
- Application Load Balancer (ALB) with listeners
- Security groups for different layers (ALB, EC2, RDS)
- Route53 hosted zone (if configured)

**Why shared?** These resources are expensive to create/destroy and can be reused across multiple application versions, reducing costs and deployment time.

### 3. Application Environments

Each application environment (blue/green) is deployed in isolated Terraform workspaces:

```bash
cd app1
# Deploy blue
terraform workspace select blue
terraform init -backend-config=backend-blue.conf
terraform plan -var-file=blue.tfvars
terraform apply -var-file=blue.tfvars

# Deploy green
terraform workspace select green
terraform init -backend-config=backend-green.conf
terraform plan -var-file=green.tfvars
terraform apply -var-file=green.tfvars
```

**What it creates:**
- EC2 instances with auto-scaling groups
- RDS MySQL database instances
- Target groups and listeners for ALB routing
- IAM roles and policies for EC2 access
- Secrets Manager entries for database credentials

## Blue-Green Deployment Logic

### Environment Isolation

- **Terraform Workspaces**: Each environment (blue/green) uses a separate workspace
- **State Separation**: Each environment has its own S3 bucket/key for state
- **Resource Naming**: All resources include environment-specific identifiers
- **ALB Routing**: Different ports/routes for blue (port 80) vs green (port 81)

### Traffic Switching

```hcl
# ALB Listener configuration (in shared/main.tf)
resource "aws_lb_listener" "http" {
  # Blue environment routes to port 80
  # Green environment routes to port 81
  port     = terraform.workspace == "blue" ? 80 : 81
  protocol = "HTTP"
}
```

### Database Handling

- Each environment gets its own RDS instance
- Database names follow clean naming: `app1blue`, `app1green`
- Credentials stored in AWS Secrets Manager
- Connection strings available via Terraform outputs

## Automation Scripts

### Quick Deployment

```bash
# Deploy blue environment
./scripts/apply-blue.sh

# Deploy green environment
./scripts/apply-green.sh
```

### Interactive Deployment

```bash
./scripts/interactive-deploy.sh
# Prompts for app, environment, and action
```

### Environment Teardown

```bash
./scripts/teardown.sh
# Destroys blue, green, and shared (preserves bootstrap)
```

## Benefits of This Architecture

### 1. **Cost Optimization**
- Shared resources reduce duplication
- Bootstrap infrastructure is preserved between deployments
- Pay only for what you use in each environment

### 2. **Environment Isolation**
- Complete separation between blue and green
- Independent scaling and testing
- Safe rollback capabilities

### 3. **Rapid Deployment**
- Parallel environment deployment
- Minimal shared resource conflicts
- Automated scripts for consistency

### 4. **Scalability**
- Modular design allows adding more applications
- Environment-specific configurations
- Easy to extend with additional environments

### 5. **Operational Safety**
- Confirmation prompts for destructive operations
- State isolation prevents cross-environment issues
- Clear separation of concerns

## Usage Examples

### Initial Setup
```bash
# 1. Bootstrap infrastructure
cd bootstrap && terraform apply

# 2. Deploy shared resources
cd ../shared && terraform apply

# 3. Deploy blue environment
cd ../app1 && ./scripts/apply-blue.sh

# 4. Test blue environment
curl http://your-alb-dns-name

# 5. Deploy green environment
./scripts/apply-green.sh

# 6. Test green environment
curl http://your-alb-dns-name:81
```

### Blue-Green Switching
```bash
# Update ALB to route to green (port 81)
# Or implement DNS switching
# Or use weighted routing for canary deployments
```

### Cleanup
```bash
./scripts/teardown.sh
# Type "DESTROY" to confirm
```

## Security Considerations

- **Secrets Management**: Database credentials in AWS Secrets Manager
- **IAM Least Privilege**: EC2 instances have minimal required permissions
- **Network Security**: Security groups follow defense-in-depth
- **State Security**: S3 buckets encrypted, DynamoDB for locking

## Monitoring and Observability

- CloudWatch metrics for all resources
- ALB access logs for traffic analysis
- RDS performance insights
- EC2 instance monitoring

## Future Enhancements

- Add CloudFront for global distribution
- Implement auto-scaling policies
- Add monitoring dashboards
- Integrate with CI/CD pipelines
- Add backup and disaster recovery

## Troubleshooting

### Common Issues

1. **State Lock Errors**: Check DynamoDB for stuck locks
2. **Backend Config Issues**: Ensure S3 buckets exist from bootstrap
3. **Workspace Conflicts**: Use `terraform workspace list` to check active workspace
4. **Resource Dependencies**: Always deploy shared resources before app environments

### Debug Commands

```bash
# Check workspaces
terraform workspace list

# Check state
terraform state list

# Refresh state
terraform refresh

# Unlock state (if needed)
terraform force-unlock LOCK_ID
```

This POC demonstrates enterprise-grade infrastructure patterns that can scale from development to production environments.