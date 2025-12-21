# =================================================================================
# Module: networking/vpc
# =================================================================================
# Purpose: 
#   Virtual Private Cloud configuration with DNS support
#
# Resources:
#   - aws_vpc.main - Main VPC (10.0.0.0/16)
#
# Outputs:
#   - vpc_id - VPC identifier
#   - vpc_cidr_block - VPC CIDR block
#
# Dependencies:
#   None - Foundation resource
#
# Notes:
#   - DNS hostnames enabled for internal name resolution
#   - DNS support enabled for Route53 private hosted zones
# =================================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
