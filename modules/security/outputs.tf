# =================================================================================
# Module: security/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

# ---------------------------------------------------------------------------------
# KMS Key Outputs
# ---------------------------------------------------------------------------------

output "kms_ebs_key_id" {
  description = "KMS key ID for EBS volumes"
  value       = aws_kms_key.ebs.id
}

output "kms_ebs_key_arn" {
  description = "KMS key ARN for EBS volumes"
  value       = aws_kms_key.ebs.arn
}

output "kms_rds_key_id" {
  description = "KMS key ID for RDS"
  value       = aws_kms_key.rds.id
}

output "kms_rds_key_arn" {
  description = "KMS key ARN for RDS"
  value       = aws_kms_key.rds.arn
}

output "kms_s3_key_id" {
  description = "KMS key ID for S3"
  value       = aws_kms_key.s3.id
}

output "kms_s3_key_arn" {
  description = "KMS key ARN for S3"
  value       = aws_kms_key.s3.arn
}

output "kms_secrets_key_id" {
  description = "KMS key ID for Secrets Manager"
  value       = aws_kms_key.secrets.id
}

output "kms_secrets_key_arn" {
  description = "KMS key ARN for Secrets Manager"
  value       = aws_kms_key.secrets.arn
}

# ---------------------------------------------------------------------------------
# Secrets Manager Outputs
# ---------------------------------------------------------------------------------

output "db_password_secret_arn" {
  description = "ARN of RDS password secret"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}

output "db_password_secret_name" {
  description = "Name of RDS password secret"
  value       = aws_secretsmanager_secret.db_password.name
}

output "mailgun_api_key_secret_arn" {
  description = "ARN of Mailgun API key secret"
  value       = aws_secretsmanager_secret.mailgun_api_key.arn
  sensitive   = true
}

output "mailgun_api_key_secret_name" {
  description = "Name of Mailgun API key secret"
  value       = aws_secretsmanager_secret.mailgun_api_key.name
}

output "mailgun_domain_secret_arn" {
  description = "ARN of Mailgun domain secret"
  value       = aws_secretsmanager_secret.mailgun_domain.arn
  sensitive   = true
}

output "mailgun_domain_secret_name" {
  description = "Name of Mailgun domain secret"
  value       = aws_secretsmanager_secret.mailgun_domain.name
}

# ---------------------------------------------------------------------------------
# Database Password (for direct use by Terraform)
# ---------------------------------------------------------------------------------

output "db_password" {
  description = "Generated database password"
  value       = random_password.db_password.result
  sensitive   = true
}
