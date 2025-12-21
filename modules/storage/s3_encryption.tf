# =================================================================================
# Module: storage/s3_encryption
# =================================================================================
# Purpose: 
#   Server-side encryption configuration for S3 bucket
#
# Encryption:
#   - Algorithm: aws:kms (customer-managed key)
#   - Bucket key enabled for cost optimization
#
# Benefits:
#   - Data encrypted at rest
#   - Key rotation managed by KMS
#   - Access controlled via IAM + KMS policies
#
# Notes:
#   - All new objects are automatically encrypted
#   - Bucket key reduces KMS API calls (cost savings)
# =================================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_s3_key_arn
    }
    bucket_key_enabled = true
  }
}
