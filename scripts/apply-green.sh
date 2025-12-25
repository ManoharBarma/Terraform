#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR="$ROOT_DIR/app1"

# Get backend-config and tfvars (plain machine-readable output)
read -r BACKEND_CONFIG < <($SCRIPT_DIR/select-env.sh green --plain | sed -n '1p')
read -r TFVARS < <($SCRIPT_DIR/select-env.sh green --plain | sed -n '2p')

cd "$APP_DIR"
terraform init -backend-config="$BACKEND_CONFIG" -reconfigure
terraform plan -var-file="$TFVARS"
terraform apply -var-file="$TFVARS"
