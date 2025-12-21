# =================================================================================
# Module: serverless/lambda/variables
# =================================================================================
# Purpose: Input variables for Lambda module
# =================================================================================

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds"
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda memory size in MB"
}

variable "lambda_placeholder_path" {
  type        = string
  description = "Path to Lambda placeholder ZIP file"
}

variable "domain_name" {
  type        = string
  description = "Application domain name"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN to subscribe to"
}

variable "mailgun_api_key_secret_arn" {
  type        = string
  description = "Mailgun API key secret ARN"
}

variable "mailgun_domain_secret_arn" {
  type        = string
  description = "Mailgun domain secret ARN"
}

variable "kms_secrets_key_arn" {
  type        = string
  description = "KMS key ARN for secrets decryption"
}
