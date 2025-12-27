#!/usr/bin/env bash
set -euo pipefail

# Teardown script to destroy blue, green, and shared environments
# Keeps bootstrap as it contains state buckets and won't cost more

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
APP_DIR="$ROOT_DIR/app1"
SHARED_DIR="$ROOT_DIR/shared"

echo "Starting teardown of environments..."

# Destroy blue environment
echo "Destroying blue environment..."
cd "$APP_DIR"
terraform workspace select blue
terraform destroy -var-file=blue.tfvars --auto-approve

# Destroy green environment
echo "Destroying green environment..."
terraform workspace select green
terraform destroy -var-file=green.tfvars --auto-approve

# Destroy shared environment
echo "Destroying shared environment..."
cd "$SHARED_DIR"
terraform destroy --auto-approve

echo "Teardown complete. Bootstrap environment preserved."