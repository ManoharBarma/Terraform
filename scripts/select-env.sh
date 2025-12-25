#!/usr/bin/env bash
set -euo pipefail

# select-env.sh: print the backend-config and tfvars file to use
# Usage: select-env.sh <blue|green> [--init]

HERE=$(cd "$(dirname "$0")/.." && pwd)
APP_DIR="$HERE/app1"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <blue|green> [--plain|--init]" >&2
  exit 2
fi

ENV="$1"
FLAG="${2-}"
case "$ENV" in
  blue)
    BACKEND_SRC_BASE="$APP_DIR/backend-blue.conf"
    TFVARS="$APP_DIR/blue.tfvars"
    ;;
  green)
    BACKEND_SRC_BASE="$APP_DIR/backend-green.conf"
    TFVARS="$APP_DIR/green.tfvars"
    ;;
  *)
    echo "Unknown env: $ENV" >&2
    exit 2
    ;;
esac

BACKEND_BLUE="$APP_DIR/backend-blue.conf"
BACKEND_GREEN="$APP_DIR/backend-green.conf"

if [ ! -f "$BACKEND_BLUE" ] || [ ! -f "$BACKEND_GREEN" ]; then
  echo "Backend config files missing in $APP_DIR" >&2
  exit 1
fi

if [ "$ENV" = "blue" ]; then
  BACKEND_CONFIG="$BACKEND_BLUE"
else
  BACKEND_CONFIG="$BACKEND_GREEN"
fi

if [ "$FLAG" = "--plain" ]; then
  # plain machine-readable output: backend-config-file<newline>tfvars-file
  printf '%s
%s
' "$BACKEND_CONFIG" "$TFVARS"
  exit 0
fi

echo "Selected environment: $ENV"
echo "Backend config: $BACKEND_CONFIG"
echo "Use tfvars: $TFVARS"
echo "$BACKEND_CONFIG"
echo "$TFVARS"
if [ "$FLAG" = "--init" ]; then
  echo "Running terraform init with backend config..."
  (cd "$APP_DIR" && terraform init -backend-config="$BACKEND_CONFIG" -reconfigure)
fi
