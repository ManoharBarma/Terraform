#!/usr/bin/env bash
set -euo pipefail

# Interactive deploy script
# Prompts for application directory (app1/app2/app3), environment (blue/green), and action (apply/destroy)
# Runs terraform init/plan/apply or terraform destroy accordingly with safety confirmations for destroy.

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
APPS=(app1 app2 app3)
ENVS=(blue green)

echo "Available apps: ${APPS[*]}"
read -rp "Enter app name (e.g. app1): " APP

# validate app
if [[ ! " ${APPS[*]} " =~ " ${APP} " ]]; then
  echo "Invalid app: $APP" >&2
  exit 1
fi

read -rp "Enter environment (blue/green): " ENV
if [[ ! " ${ENVS[*]} " =~ " ${ENV} " ]]; then
  echo "Invalid environment: $ENV" >&2
  exit 1
fi

read -rp "Action (apply/destroy): " ACTION
if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
  echo "Invalid action: $ACTION" >&2
  exit 1
fi

APP_DIR="$ROOT_DIR/$APP"
BACKEND_CONF="$APP_DIR/backend-${ENV}.conf"
TFVARS="$APP_DIR/${ENV}.tfvars"

if [ ! -d "$APP_DIR" ]; then
  echo "App directory not found: $APP_DIR" >&2
  exit 2
fi

if [ ! -f "$BACKEND_CONF" ]; then
  echo "Backend config not found: $BACKEND_CONF" >&2
  exit 2
fi

if [ ! -f "$TFVARS" ]; then
  echo "Variables file not found: $TFVARS" >&2
  exit 2
fi

# run terraform commands
cd "$APP_DIR"

echo "Initializing Terraform in $APP_DIR with backend $BACKEND_CONF"
terraform init -backend-config="backend-${ENV}.conf" -reconfigure

if [ "$ACTION" = "apply" ]; then
  echo "Planning"
  terraform plan -var-file="${ENV}.tfvars"
  echo "Applying"
  terraform apply -var-file="${ENV}.tfvars" --auto-approve
  echo "Apply complete"
else
  echo "You are about to DESTROY resources for $APP in $ENV"
  read -rp "Type THE_WORD ""DESTROY"" to confirm: " CONFIRM
  if [ "$CONFIRM" != "DESTROY" ]; then
    echo "Destroy cancelled"
    exit 0
  fi
  terraform destroy -var-file="${ENV}.tfvars" --auto-approve
  echo "Destroy complete"
fi
