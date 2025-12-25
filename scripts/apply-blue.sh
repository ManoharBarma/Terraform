#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
APP_DIR="$ROOT_DIR/app1"

# Get backend-config and tfvars (plain machine-readable output)
readarray -t CFG < <($SCRIPT_DIR/select-env.sh blue --plain)
BACKEND_CONFIG="${CFG[0]:-}"
TFVARS="${CFG[1]:-}"

if [ -z "$BACKEND_CONFIG" ] || [ -z "$TFVARS" ]; then
	echo "Failed to determine backend-config or tfvars. Run: $SCRIPT_DIR/select-env.sh blue --plain" >&2
	exit 2
fi

if [ ! -f "$TFVARS" ]; then
	echo "Variables file not found: $TFVARS" >&2
	echo "Create the file or update app1/blue.tfvars with appropriate values." >&2
	exit 2
fi

terraform -chdir="$APP_DIR" init -backend-config="$BACKEND_CONFIG" -reconfigure
terraform -chdir="$APP_DIR" plan -var-file="$TFVARS"
terraform -chdir="$APP_DIR" apply -var-file="$TFVARS"
