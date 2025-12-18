# ===================================================================
# Target Group for Load Balancer (a list of targeted EC2)
# ===================================================================

resource "aws_lb_target_group" "webapp" {
  name     = "${var.vpc_name}-webapp-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health Check 設定
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

  # Deregistration delay (instance 移除前等待時間，讓剩餘requests跑完)
  deregistration_delay = 30

  tags = {
    Name = "${var.vpc_name}-webapp-tg"
  }
}

# ===================================================================
# Application Load Balancer
# ===================================================================

resource "aws_lb" "webapp" {
  name               = "${var.vpc_name}-webapp-alb"
  internal           = false         # face to public network
  load_balancer_type = "application" # Layer 7 (HTTP/HTTPS)
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public[*].id # deploy on all public subnets

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name = "${var.vpc_name}-webapp-alb"
  }
}

# ===================================================================
# Load Balancer Listener (Port 80)
# ===================================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.webapp.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}

# ===================================================================
# Outputs
# ===================================================================

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.webapp.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.webapp.arn
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.webapp.arn
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer (for Route53 alias)"
  value       = aws_lb.webapp.zone_id
}