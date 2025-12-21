# =================================================================================
# Module: serverless/sns/topic
# =================================================================================
# Purpose: 
#   SNS topic for user email verification notifications
#
# Architecture:
#   User Registration → Spring Boot → SNS Topic → Lambda → Email
#
# Topic Configuration:
#   - Encrypted using KMS customer-managed key
#   - Standard topic (not FIFO) for high throughput
#   - Subscribed by Lambda function
#
# Message Format:
#   {
#     "email": "user@example.com",
#     "token": "uuid-verification-token",
#     "firstName": "John"
#   }
#
# Notes:
#   - EC2 instances publish messages via IAM role
#   - Lambda is automatically triggered on message arrival
#   - Message encryption protects sensitive user data
# =================================================================================

resource "aws_sns_topic" "user_verification" {
  name         = "${var.project_name}-${var.environment}-user-verification"
  display_name = "User Email Verification"

  # Encryption
  kms_master_key_id = var.kms_secrets_key_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-verification"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "EmailVerification"
    ManagedBy   = "terraform"
  }
}
