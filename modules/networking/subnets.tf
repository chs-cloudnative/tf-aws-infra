# =================================================================================
# Module: networking/subnets
# =================================================================================
# Purpose: 
#   Public and private subnet configuration across multiple availability zones
#
# Resources:
#   - aws_subnet.public[3] - Public subnets with auto-assign public IP
#   - aws_subnet.private[3] - Private subnets for RDS
#
# Architecture:
#   Each subnet is placed in a different AZ for high availability
#   - us-east-1a: public-1 (10.0.1.0/24), private-1 (10.0.11.0/24)
#   - us-east-1b: public-2 (10.0.2.0/24), private-2 (10.0.12.0/24)
#   - us-east-1c: public-3 (10.0.3.0/24), private-3 (10.0.13.0/24)
#
# Notes:
#   - Public subnets auto-assign public IPs for EC2 instances
#   - Private subnets used for RDS instances (no direct internet access)
# =================================================================================

# ---------------------------------------------------------------------------------
# Data Source: Available Availability Zones
# ---------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# ---------------------------------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Private Subnets
# ---------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
    ManagedBy   = "terraform"
  }
}
