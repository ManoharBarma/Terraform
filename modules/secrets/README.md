# Secrets Module

Creates an AWS Secrets Manager secret and a random password as a secret version.

Inputs:
- `secret_name` (string) - name/path for the secret.
- `tags` (map) - optional tags.

Outputs:
- `secret_arn` - ARN of the created secret.
- `secret_id` - ID of the created secret.

Notes:
- This module intentionally does not expose the raw secret value as an output. Use the `secret_arn` and grant the IAM role permission to call `secretsmanager:GetSecretValue`.
