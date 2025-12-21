# =================================================================================
# Module: compute/load_balancer
# =================================================================================
# Purpose: 
#   Application Load Balancer and Target Group for traffic distribution
#
# Components:
#   1. Target Group - Define backend instances and health checks
#   2. Application Load Balancer - Public-facing load balancer
#   3. HTTP Listener - Forward traffic to target group
#
# Architecture:
#   Internet → ALB (Port 80) → Target Group → EC2 Instances (Port 8080)
#
# Health Checks:
#   - Path: /health
#   - Interval: 30 seconds
#   - Timeout: 5 seconds
#   - Healthy threshold: 2 consecutive successes
#   - Unhealthy threshold: 2 consecutive failures
#
# Notes:
#   - HTTPS (Port 443) will be added in SSL certificate phase
#   - ALB automatically removes unhealthy instances from rotation
#   - Deregistration delay: 30s (allow in-flight requests to complete)
# =================================================================================

# ---------------------------------------------------------------------------------
# Target Group
# ---------------------------------------------------------------------------------

resource "aws_lb_target_group" "webapp" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  # Deregistration delay (drain time)
  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------------

resource "aws_lb" "webapp" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.load_balancer_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# HTTP Listener (Port 80)
# ---------------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
