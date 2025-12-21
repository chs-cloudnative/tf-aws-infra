# =================================================================================
# Module: security/kms_keys
# =================================================================================
# Purpose: 
#   Customer-managed KMS keys for encrypting various AWS resources
#
# Resources:
#   - EBS volumes encryption key
#   - RDS database encryption key
#   - S3 bucket encryption key
#   - Secrets Manager encryption key
#
# Key Features:
#   - Automatic key rotation every 365 days
#   - 10-day deletion window for safety
#   - Separate keys for each service (least privilege principle)
#
# Notes:
#   - Key rotation is transparent to applications
#   - Old data continues to use old key versions
#   - New data uses new key versions
# =================================================================================

# ---------------------------------------------------------------------------------
# KMS Key for EBS Volumes
# ---------------------------------------------------------------------------------

resource "aws_kms_key" "ebs" {
  description             = "KMS key for encrypting EBS volumes"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ebs-kms"
    Environment = var.environment
    Project     = var.project_name
    Service     = "EC2"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# ---------------------------------------------------------------------------------
# KMS Key for RDS Database
# ---------------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description             = "KMS key for encrypting RDS database"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-kms"
    Environment = var.environment
    Project     = var.project_name
    Service     = "RDS"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ---------------------------------------------------------------------------------
# KMS Key for S3 Buckets
# ---------------------------------------------------------------------------------

resource "aws_kms_key" "s3" {
  description             = "KMS key for encrypting S3 objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-s3-kms"
    Environment = var.environment
    Project     = var.project_name
    Service     = "S3"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# ---------------------------------------------------------------------------------
# KMS Key for Secrets Manager
# ---------------------------------------------------------------------------------

resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-secrets-kms"
    Environment = var.environment
    Project     = var.project_name
    Service     = "SecretsManager"
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
