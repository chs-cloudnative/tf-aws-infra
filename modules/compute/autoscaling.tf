# =================================================================================
# Module: compute/autoscaling
# =================================================================================
# Purpose: 
#   Auto Scaling Group for high availability and automatic scaling
#
# Configuration:
#   - Min size: 3 instances (HA across 3 AZs)
#   - Max size: 5 instances (cost control)
#   - Desired capacity: 3 instances (normal operation)
#   - Health check: ELB (application-level)
#
# Instance Refresh:
#   - Rolling update strategy
#   - Min healthy: 50% (at least 2 instances during update)
#   - Triggered automatically when launch template changes
#
# High Availability:
#   - Instances distributed across 3 availability zones
#   - Auto-replace unhealthy instances
#   - Integrated with Application Load Balancer
#
# Notes:
#   - Health check grace period: 300s (allow app startup time)
#   - Uses latest launch template version automatically
# =================================================================================

resource "aws_autoscaling_group" "webapp" {
  name                      = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [aws_lb_target_group.webapp.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Tags propagated to instances
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-webapp-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  wait_for_capacity_timeout = "10m"
}
