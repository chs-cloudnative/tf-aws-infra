# =================================================================================
# Module: storage/variables
# =================================================================================
# Purpose: Input variables for storage module
# =================================================================================

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
}

variable "kms_s3_key_arn" {
  type        = string
  description = "KMS key ARN for S3 encryption"
}
