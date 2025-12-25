#!/usr/bin/env bash
set -euo pipefail

# Run terraform fmt recursively from repo root
ROOT=$(cd "$(dirname "$0")/.." && pwd)
echo "Running terraform fmt in $ROOT"
find "$ROOT" -name '*.tf' -print0 | xargs -0 -n1 dirname | sort -u | while read -r dir; do
  echo "Formatting: $dir"
  terraform -chdir="$dir" fmt -recursive
done
