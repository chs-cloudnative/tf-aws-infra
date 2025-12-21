# =================================================================================
# Module: serverless/sns/variables
# =================================================================================
# Purpose: Input variables for SNS module
# =================================================================================

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
}

variable "kms_secrets_key_id" {
  type        = string
  description = "KMS key ID for SNS encryption"
}
