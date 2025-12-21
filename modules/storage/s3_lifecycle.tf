# =================================================================================
# Module: storage/s3_lifecycle
# =================================================================================
# Purpose: 
#   Lifecycle policy for cost optimization
#
# Policy:
#   - Transition objects to STANDARD_IA after 30 days
#
# Cost Optimization:
#   - STANDARD: $0.023/GB (frequent access)
#   - STANDARD_IA: $0.0125/GB (infrequent access)
#   - ~46% cost reduction for older images
#
# Notes:
#   - Suitable for product images that become less accessed over time
#   - Can add GLACIER transition for archival if needed
# =================================================================================

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
