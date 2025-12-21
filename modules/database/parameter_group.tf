# =================================================================================
# Module: database/parameter_group
# =================================================================================
# Purpose: 
#   PostgreSQL parameter group for database configuration
#
# Resources:
#   - aws_db_parameter_group.main - PostgreSQL 16 configuration
#
# Parameters:
#   - client_encoding: UTF8 for international character support
#   - timezone: UTC for consistent timestamps
#
# Notes:
#   - Parameter group family must match PostgreSQL version
#   - Changes to some parameters require database restart
# =================================================================================

resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-postgres-params"
  family = "postgres16"

  parameter {
    name  = "client_encoding"
    value = "UTF8"
  }

  parameter {
    name  = "timezone"
    value = "UTC"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-params"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
