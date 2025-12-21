# =================================================================================
# Module: compute/scaling_policies
# =================================================================================
# Purpose: 
#   Auto scaling policies and CloudWatch alarms for dynamic capacity management
#
# Scaling Strategy:
#   - Scale Up: When average CPU > 12% for 2 minutes
#   - Scale Down: When average CPU < 8% for 2 minutes
#   - Cooldown: 60 seconds between scaling actions
#
# Scaling Actions:
#   - Scale Up: Add 1 instance
#   - Scale Down: Remove 1 instance
#
# Benefits:
#   - Cost optimization (scale down during low traffic)
#   - Performance guarantee (scale up during high traffic)
#   - Gradual scaling (prevent over-provisioning)
#
# Notes:
#   - Thresholds are low for demo purposes
#   - Production should use higher thresholds (e.g., 70%/30%)
#   - Consider using target tracking scaling for simpler config
# =================================================================================

# ---------------------------------------------------------------------------------
# Scale Up Policy
# ---------------------------------------------------------------------------------

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# ---------------------------------------------------------------------------------
# CloudWatch Alarm: High CPU (Trigger Scale Up)
# ---------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 12

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp.name
  }

  alarm_description = "Triggers scale up when CPU > 12%"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-cpu-high-alarm"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# Scale Down Policy
# ---------------------------------------------------------------------------------

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# ---------------------------------------------------------------------------------
# CloudWatch Alarm: Low CPU (Trigger Scale Down)
# ---------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 8

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp.name
  }

  alarm_description = "Triggers scale down when CPU < 8%"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]

  tags = {
    Name        = "${var.project_name}-${var.environment}-cpu-low-alarm"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
