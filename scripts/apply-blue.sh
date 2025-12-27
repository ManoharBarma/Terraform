#!/usr/bin/env bash
set -euo pipefail

# Simple convenience script to init/plan/apply the blue environment
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
APP_DIR="$ROOT_DIR/app1"
BACKEND_CONFIG="$APP_DIR/backend-blue.conf"
TFVARS="$APP_DIR/blue.tfvars"

echo "Applying blue environment using backend: $BACKEND_CONFIG and tfvars: $TFVARS"

if [ ! -f "$BACKEND_CONFIG" ]; then
  echo "Backend config not found: $BACKEND_CONFIG" >&2
  exit 2
fi

if [ ! -f "$TFVARS" ]; then
  echo "Variables file not found: $TFVARS" >&2
  echo "Create $TFVARS or copy the sample file." >&2
  exit 2
fi

terraform -chdir="$APP_DIR" init -backend-config=backend-blue.conf -reconfigure
terraform -chdir="$APP_DIR" plan -var-file=blue.tfvars
terraform -chdir="$APP_DIR" apply -var-file=blue.tfvars --auto-approve
#terraform -chdir="$APP_DIR" destroy -var-file=blue.tfvars --auto-approve