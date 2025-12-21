# =================================================================================
# Module: security/variables
# =================================================================================
# Purpose: Input variables for security module
# =================================================================================

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
}

variable "mailgun_api_key" {
  type        = string
  description = "Mailgun API key"
  sensitive   = true
}

variable "mailgun_domain" {
  type        = string
  description = "Mailgun domain"
}

variable "kms_secrets_key_id" {
  type        = string
  description = "KMS key ID for Secrets Manager (passed from own module output)"
  default     = ""
}
