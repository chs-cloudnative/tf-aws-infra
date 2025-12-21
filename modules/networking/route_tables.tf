# =================================================================================
# Module: networking/route_tables
# =================================================================================
# Purpose: 
#   Internet Gateway and routing configuration for public/private subnets
#
# Resources:
#   - aws_internet_gateway.main - IGW for internet access
#   - aws_route_table.public - Route table for public subnets
#   - aws_route_table.private - Route table for private subnets
#   - Route table associations
#
# Routing Logic:
#   Public subnets: 0.0.0.0/0 → Internet Gateway
#   Private subnets: No default route (isolated)
#
# Notes:
#   - Public subnets can reach internet via IGW
#   - Private subnets have no internet access (RDS security)
# =================================================================================

# ---------------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Public Route Table
# ---------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
    ManagedBy   = "terraform"
  }
}

# Public Route: Internet access via IGW
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------------
# Private Route Table
# ---------------------------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private"
    ManagedBy   = "terraform"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
