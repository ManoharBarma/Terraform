#!/usr/bin/env bash
set -euo pipefail

# Simple convenience script to init/plan/apply the green environment
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
APP_DIR="$ROOT_DIR/app1"
BACKEND_CONFIG="$APP_DIR/backend-green.conf"
TFVARS="$APP_DIR/green.tfvars"

echo "Applying green environment using backend: $BACKEND_CONFIG and tfvars: $TFVARS"

if [ ! -f "$BACKEND_CONFIG" ]; then
	echo "Backend config not found: $BACKEND_CONFIG" >&2
	exit 2
fi

if [ ! -f "$TFVARS" ]; then
	echo "Variables file not found: $TFVARS" >&2
	echo "Create $TFVARS or copy the sample file." >&2
	exit 2
fi

cd "$APP_DIR"
terraform init -backend-config="backend-green.conf" -reconfigure
terraform workspace select green || terraform workspace new green
terraform plan -var-file="green.tfvars"
terraform apply -var-file="green.tfvars" --auto-approve
#terraform -chdir="$APP_DIR" destroy -var-file=green.tfvars --auto-approve
