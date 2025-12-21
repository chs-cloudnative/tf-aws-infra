# =================================================================================
# Module: serverless/lambda/function
# =================================================================================
# Purpose: 
#   Lambda function to send email verification messages
#
# Trigger:
#   - SNS topic notification (user registration event)
#
# Function Logic:
#   1. Receive SNS event with user details
#   2. Retrieve Mailgun credentials from Secrets Manager
#   3. Build verification email with token link
#   4. Send email via Mailgun API
#
# Environment Variables:
#   - APP_DOMAIN: Application domain for verification links
#
# Runtime:
#   - Python 3.11
#   - Timeout: 30 seconds (email sending)
#   - Memory: 256 MB
#
# Notes:
#   - Uses placeholder code initially
#   - Actual code deployed via CI/CD (serverless repo)
#   - SNS subscription and permission configured separately
# =================================================================================

resource "aws_lambda_function" "email_handler" {
  function_name = "${var.project_name}-${var.environment}-email-handler"
  role          = aws_iam_role.lambda.arn
  handler       = "email_handler.lambda_handler"

  # Runtime configuration
  runtime     = var.lambda_runtime
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  # Placeholder code (will be updated by CI/CD)
  filename         = var.lambda_placeholder_path
  source_code_hash = filebase64sha256(var.lambda_placeholder_path)

  # Environment variables
  environment {
    variables = {
      APP_DOMAIN = var.domain_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-email-handler"
    Environment = var.environment
    Project     = var.project_name
    Service     = "Lambda"
    Purpose     = "EmailVerification"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# SNS Subscription
# ---------------------------------------------------------------------------------
# Subscribe Lambda to SNS topic

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_handler.arn
}

# ---------------------------------------------------------------------------------
# Lambda Permission
# ---------------------------------------------------------------------------------
# Allow SNS to invoke Lambda function

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}
