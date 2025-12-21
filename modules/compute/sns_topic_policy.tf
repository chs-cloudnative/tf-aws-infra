# =================================================================================
# Module: compute/sns_topic_policy
# =================================================================================
# Purpose: 
#   Allow EC2 instances to publish messages to SNS topic
#
# Policy Type:
#   - Resource-based policy (attached to SNS topic)
#   - Allows specific IAM role to publish
#
# Security:
#   - Only EC2 role can publish to this topic
#   - No public access
#
# Notes:
#   - This is in compute module to avoid circular dependency
#   - SNS topic created first, then EC2 role, then this policy
# =================================================================================

resource "aws_sns_topic_policy" "user_verification" {
  arn = var.sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2ToPublish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2.arn
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = var.sns_topic_arn
      }
    ]
  })
}
