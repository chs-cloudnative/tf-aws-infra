# =================================================================================
# Module: storage/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

output "s3_bucket_id" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.images.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.images.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.images.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.images.bucket_regional_domain_name
}
