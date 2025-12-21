# =================================================================================
# Module: networking/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

# ---------------------------------------------------------------------------------
# VPC Outputs
# ---------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

# ---------------------------------------------------------------------------------
# Subnet Outputs
# ---------------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

# ---------------------------------------------------------------------------------
# Route Table Outputs
# ---------------------------------------------------------------------------------

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

# ---------------------------------------------------------------------------------
# Security Group Outputs
# ---------------------------------------------------------------------------------

output "load_balancer_security_group_id" {
  description = "Load Balancer security group ID"
  value       = aws_security_group.load_balancer.id
}

output "application_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.database.id
}

# ---------------------------------------------------------------------------------
# Availability Zones
# ---------------------------------------------------------------------------------

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}
