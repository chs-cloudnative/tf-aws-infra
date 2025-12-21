# =================================================================================
# Module: networking/security_groups
# =================================================================================
# Purpose: 
#   Security group definitions for all application components
#
# Security Groups:
#   1. Load Balancer SG - Public facing (HTTP/HTTPS)
#   2. Application SG - EC2 instances (from ALB + SSH)
#   3. Database SG - RDS instances (from Application SG)
#
# Security Model:
#   Internet → ALB (80/443) → EC2 (8080) → RDS (5432)
#
# Notes:
#   - SSH access to EC2 is allowed from anywhere (should be restricted in prod)
#   - Database only accepts connections from application security group
# =================================================================================

# ---------------------------------------------------------------------------------
# Load Balancer Security Group
# ---------------------------------------------------------------------------------

resource "aws_security_group" "load_balancer" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Inbound: HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: HTTPS from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
    Component   = "networking"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Application Security Group (EC2 Instances)
# ---------------------------------------------------------------------------------

resource "aws_security_group" "application" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application EC2 instances"
  vpc_id      = aws_vpc.main.id

  # Inbound: SSH from anywhere (consider restricting in production)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: Application port from Load Balancer only
  ingress {
    description     = "Application port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  # Outbound: Allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
    Project     = var.project_name
    Component   = "networking"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Database Security Group
# ---------------------------------------------------------------------------------

resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = aws_vpc.main.id

  # Inbound: PostgreSQL from Application SG only
  ingress {
    description     = "PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Outbound: Allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
    Project     = var.project_name
    Component   = "networking"
    ManagedBy   = "terraform"
  }
}
