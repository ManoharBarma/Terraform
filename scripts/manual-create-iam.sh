#!/usr/bin/env bash
set -euo pipefail

# Manual IAM creation + Terraform import helper
# Usage: ./scripts/manual-create-iam.sh [--app APP_NAME] [--region REGION] [--secret-arn SECRET_ARN]
# Example: ./scripts/manual-create-iam.sh --app app1-blue --region us-west-1 --secret-arn arn:aws:secretsmanager:us-west-1:123:secret:...

APP_NAME="app1-blue"
REGION="us-west-1"
SECRET_ARN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_NAME="$2"; shift 2 ;;
    --region)
      REGION="$2"; shift 2 ;;
    --secret-arn)
      SECRET_ARN="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--app APP_NAME] [--region REGION] [--secret-arn SECRET_ARN]"; exit 0 ;;
    *)
      echo "Unknown arg: $1"; exit 2 ;;
  esac
done

ROLE_NAME="${APP_NAME}-ec2-role"
POLICY_NAME="${ROLE_NAME}-policy"

echo "Using APP_NAME=$APP_NAME, ROLE_NAME=$ROLE_NAME, REGION=$REGION"

if [ -z "${AWS_REGION-}" ]; then
  export AWS_REGION="$REGION"
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI not found. Install and configure aws CLI before running." >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Note: 'jq' not found. Script will attempt to parse JSON with aws CLI queries." >&2
fi

# Check for CA cert issues common in clean WSL images
if ! python3 -c "import ssl; print(ssl.get_default_verify_paths().openssl_cafile)" >/dev/null 2>&1; then
  echo "Warning: Python SSL check failed. If you see certificate errors, install CA certificates in WSL: sudo apt-get update && sudo apt-get install -y ca-certificates" >&2
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "$REGION")
echo "Account: $ACCOUNT_ID"

# If secret ARN not provided, try to locate a secret containing the app name
if [ -z "$SECRET_ARN" ]; then
  echo "SECRET_ARN not provided — searching for secrets containing '$APP_NAME'..."
  # try to find a matching secret
  SECRET_ARN=$(aws secretsmanager list-secrets --region "$REGION" --query "SecretList[?contains(Name, \\`${APP_NAME}\\`)].ARN | [0]" --output text 2>/dev/null || true)
  if [ -z "$SECRET_ARN" ] || [ "$SECRET_ARN" = "None" ]; then
    echo "No matching secret found automatically. You must provide --secret-arn or set SECRET_ARN in the environment." >&2
    echo "Example: --secret-arn arn:aws:secretsmanager:${REGION}:${ACCOUNT_ID}:secret:app1-blue/..." >&2
    exit 2
  fi
  echo "Found secret ARN: $SECRET_ARN"
fi

# Create assume role policy
cat > /tmp/assume-role-${APP_NAME}.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo "Creating role $ROLE_NAME..."
set +e
ROLE_CREATE_OUT=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file:///tmp/assume-role-${APP_NAME}.json --description "IAM role for ${APP_NAME} EC2 instances" --region "$REGION" 2>&1)
ROLE_CREATE_EXIT=$?
set -e
if [ $ROLE_CREATE_EXIT -ne 0 ]; then
  if echo "$ROLE_CREATE_OUT" | grep -q "EntityAlreadyExists"; then
    echo "Role already exists — continuing.";
  else
    echo "Failed to create role: $ROLE_CREATE_OUT" >&2; exit 3;
  fi
else
  echo "Role created.";
fi

# Create policy JSON
cat > /tmp/secrets-policy-${APP_NAME}.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSecretsRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "${SECRET_ARN}"
      ]
    }
  ]
}
EOF

echo "Creating policy $POLICY_NAME..."
set +e
POL_OUT=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file:///tmp/secrets-policy-${APP_NAME}.json --region "$REGION" 2>&1)
POL_EXIT=$?
set -e
if [ $POL_EXIT -ne 0 ]; then
  if echo "$POL_OUT" | grep -q "EntityAlreadyExists"; then
    echo "Policy already exists — fetching ARN..."
    if command -v jq >/dev/null 2>&1; then
      POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].[Arn]" --region "$REGION" --output text)
    else
      POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --region "$REGION" --output text)
    fi
  else
    echo "Policy creation failed: $POL_OUT" >&2; exit 4;
  fi
else
  if command -v jq >/dev/null 2>&1; then
    POLICY_ARN=$(echo "$POL_OUT" | jq -r '.Policy.Arn')
  else
    POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --region "$REGION" --output text)
  fi
fi

echo "Policy ARN: $POLICY_ARN"

echo "Attaching policy to role..."
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN" --region "$REGION"

echo "Creating instance profile..."
set +e
aws iam create-instance-profile --instance-profile-name "$ROLE_NAME" --region "$REGION" 2>/dev/null || true
set -e
aws iam add-role-to-instance-profile --instance-profile-name "$ROLE_NAME" --role-name "$ROLE_NAME" --region "$REGION"

echo "Waiting for role and instance profile to propagate..."
TRIES=0
until aws iam get-role --role-name "$ROLE_NAME" --region "$REGION" >/dev/null 2>&1 || [ $TRIES -ge 12 ]; do
  echo "Waiting for role..."; sleep 2; TRIES=$((TRIES+1));
done

if [ $TRIES -ge 12 ]; then
  echo "Timed out waiting for role propagation." >&2
fi

echo "Verifying instance profile exists..."
aws iam get-instance-profile --instance-profile-name "$ROLE_NAME" --region "$REGION" >/dev/null 2>&1 || echo "Instance profile not found yet — it may still be propagating."

echo "Importing into Terraform state..."
# Import resources into Terraform (run from repo root)
terraform -chdir=app1 import -lock=false 'module.ec2_iam_role.aws_iam_role.this' "$ROLE_NAME" || true
terraform -chdir=app1 import -lock=false 'module.ec2_iam_role.aws_iam_policy.this' "$POLICY_ARN" || true
terraform -chdir=app1 import -lock=false 'module.ec2_iam_role.aws_iam_role_policy_attachment.this' "${ROLE_NAME}/${POLICY_ARN}" || true
terraform -chdir=app1 import -lock=false 'module.ec2_iam_role.aws_iam_instance_profile.this' "$ROLE_NAME" || true

echo "Done. Run: terraform -chdir=app1 plan -var-file=blue.tfvars" 
