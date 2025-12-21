# =================================================================================
# Module: storage/s3_bucket
# =================================================================================
# Purpose: 
#   S3 bucket for storing product images uploaded by users
#
# Resources:
#   - aws_s3_bucket.images - Main storage bucket
#   - Server-side encryption configuration
#   - Lifecycle policy for cost optimization
#   - Public access block
#
# Storage Strategy:
#   - STANDARD class for frequently accessed images
#   - Auto-transition to STANDARD_IA after 30 days
#   - Encrypted using KMS customer-managed key
#
# Access Pattern:
#   - EC2 instances write/read via IAM role
#   - No public access (private bucket)
#   - Pre-signed URLs for temporary access (if needed)
#
# Notes:
#   - Bucket name uses random UUID for global uniqueness
#   - force_destroy = true (only for dev, remove in prod)
# =================================================================================

# ---------------------------------------------------------------------------------
# Random UUID for Bucket Name
# ---------------------------------------------------------------------------------
# S3 bucket names must be globally unique
# Using UUID ensures no naming conflicts

resource "random_uuid" "bucket_name" {}

# ---------------------------------------------------------------------------------
# S3 Bucket
# ---------------------------------------------------------------------------------

resource "aws_s3_bucket" "images" {
  bucket        = "${var.project_name}-${var.environment}-images-${random_uuid.bucket_name.result}"
  force_destroy = true # Allow Terraform to delete non-empty bucket (dev only)

  tags = {
    Name        = "${var.project_name}-${var.environment}-images"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "ProductImages"
    ManagedBy   = "terraform"
  }
}
