# =================================================================================
# Module: database/rds
# =================================================================================
# Purpose: 
#   PostgreSQL RDS instance for application data storage
#
# Resources:
#   - aws_db_instance.main - PostgreSQL 16 RDS instance
#
# Features:
#   - Encrypted at rest using KMS
#   - Automated backups (7 days retention)
#   - CloudWatch logs for monitoring
#   - Multi-AZ deployment ready (can be enabled)
#
# Database Schema:
#   - Users: User accounts and authentication
#   - Products: Product catalog
#   - Images: Image metadata (actual files in S3)
#
# Security:
#   - Not publicly accessible
#   - Password stored in Secrets Manager
#   - Encrypted using customer-managed KMS key
#
# Notes:
#   - skip_final_snapshot = true (only for dev environment)
#   - Production should set this to false
# =================================================================================

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-postgres"
  engine         = "postgres"
  engine_version = "16.3"

  # Instance configuration
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.kms_rds_key_arn

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  skip_final_snapshot     = true # Set to false in production

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project_name
    Engine      = "PostgreSQL"
    Version     = "16.3"
    ManagedBy   = "terraform"
  }
}
