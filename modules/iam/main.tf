# Creates the IAM Role that EC2 instances will assume
resource "aws_iam_role" "this" {
  name = var.role_name
  path = "/"

  # This policy allows EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Defines the specific permissions for the role
resource "aws_iam_policy" "this" {
  name        = "${var.role_name}-policy"
  description = "Allows reading secrets from Secrets Manager"

  # This policy grants permission to get the secret's value
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = var.allowed_secret_arn 
      }
    ]
  })
}


# Attaches the policy to the role
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

# Creates an instance profile, which is the container for the role that gets attached to an EC2 instance
resource "aws_iam_instance_profile" "this" {
  name = var.role_name
  role = aws_iam_role.this.name
}