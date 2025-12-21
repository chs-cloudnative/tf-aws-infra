# =================================================================================
# Module: storage/s3_public_access
# =================================================================================
# Purpose: 
#   Block all public access to the S3 bucket
#
# Security:
#   - No public ACLs allowed
#   - No public bucket policies allowed
#   - Ignore any public ACLs
#   - Restrict public bucket access
#
# Access Pattern:
#   - Only EC2 instances with proper IAM role can access
#   - No direct internet access
#   - Pre-signed URLs can be generated if needed (temporary access)
#
# Notes:
#   - This is a security best practice
#   - Prevents accidental public exposure of images
# =================================================================================

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
