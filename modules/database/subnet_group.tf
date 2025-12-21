# =================================================================================
# Module: database/subnet_group
# =================================================================================
# Purpose: 
#   DB subnet group for RDS instance placement across multiple AZs
#
# Resources:
#   - aws_db_subnet_group.main - Subnet group for RDS
#
# Architecture:
#   - RDS instances are deployed in private subnets
#   - Spans multiple availability zones for high availability
#   - No direct internet access (security requirement)
#
# Notes:
#   - Minimum 2 subnets in different AZs required
#   - Private subnets ensure database is not publicly accessible
# =================================================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
