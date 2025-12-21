# =================================================================================
# Module: serverless/lambda/iam
# =================================================================================
# Purpose: 
#   IAM role and policies for Lambda function execution
#
# Role:
#   - Lambda service can assume this role
#
# Policies:
#   1. CloudWatch Logs - Write function logs
#   2. Secrets Manager - Read Mailgun credentials
#   3. KMS - Decrypt secrets
#
# Security:
#   - Least privilege principle
#   - Only access to required secrets
#   - KMS access scoped to secrets key
#
# Notes:
#   - Lambda needs these permissions to send emails
#   - Cannot access RDS password (not needed)
# =================================================================================

# ---------------------------------------------------------------------------------
# Lambda IAM Role
# ---------------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-email-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-email-role"
    Environment = var.environment
    Project     = var.project_name
    Service     = "Lambda"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Policy: CloudWatch Logs (AWS Managed)
# ---------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------------------------------
# Policy: Secrets Manager Access
# ---------------------------------------------------------------------------------

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-${var.environment}-lambda-secrets-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.mailgun_api_key_secret_arn,
          var.mailgun_domain_secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_secrets_key_arn
      }
    ]
  })
}
