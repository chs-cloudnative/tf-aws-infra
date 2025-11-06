# -------------------------------------------------------------------
# S3 Bucket for storing application images
# -------------------------------------------------------------------

# Generate a random UUID for bucket name (S3 bucket names must be globally unique)
resource "random_uuid" "s3_bucket_name" {}

# Create S3 bucket
resource "aws_s3_bucket" "webapp_images" {
  bucket        = random_uuid.s3_bucket_name.result
  force_destroy = true # Allow Terraform to delete bucket even if it contains objects

  tags = {
    Name        = "WebApp Images Bucket"
    Environment = var.environment
  }
}

# Enable default encryption for S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "webapp_images" {
  bucket = aws_s3_bucket.webapp_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configure lifecycle policy to transition objects to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "webapp_images" {
  bucket = aws_s3_bucket.webapp_images.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "webapp_images" {
  bucket = aws_s3_bucket.webapp_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}