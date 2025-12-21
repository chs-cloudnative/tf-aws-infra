# =================================================================================
# Module: serverless/sns/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

output "topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.user_verification.arn
}

output "topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.user_verification.name
}
