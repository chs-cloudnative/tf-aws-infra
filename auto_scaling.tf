# ===================================================================
# Data Source: Find Latest Custom AMI
# ===================================================================

data "aws_ami" "custom" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["csye6225-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ===================================================================
# Launch Template for Auto Scaling Group (EC2 config)
# ===================================================================

resource "aws_launch_template" "webapp" {
  name_prefix   = "${var.vpc_name}-launch-template-"
  image_id      = data.aws_ami.custom.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Network settings
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application.id]
    delete_on_termination       = true
  }

  # IAM Instance Profile
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # User Data - configuration for newly launched EC2
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host     = aws_db_instance.main.address
    db_port     = aws_db_instance.main.port
    db_name     = aws_db_instance.main.db_name
    db_user     = aws_db_instance.main.username
    db_password = var.db_password
    s3_bucket   = aws_s3_bucket.webapp_images.id
    aws_region  = var.aws_region
  }))

  # Block device mapping (root volume - hard drive config for EC2)
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Metadata options for IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.vpc_name}-webapp-asg-instance"
    }
  }

  # 確保 RDS 先建立
  depends_on = [aws_db_instance.main]
}

# ===================================================================
# Auto Scaling Group (Manage EC2s)
# ===================================================================

resource "aws_autoscaling_group" "webapp" {
  name                      = "${var.vpc_name}-webapp-asg"
  vpc_zone_identifier       = aws_subnet.public[*].id
  target_group_arns         = [aws_lb_target_group.webapp.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300 # wait for application, cloudwatch

  min_size         = 3
  max_size         = 5
  desired_capacity = 3

  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  # Instance refresh settings
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Tags for instances
  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-webapp-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  # Wait for instances to be healthy before considering deployment successful
  wait_for_capacity_timeout = "10m"

  depends_on = [aws_lb_target_group.webapp]
}

# ===================================================================
# Auto Scaling Policies - Scale Up
# ===================================================================

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.vpc_name}-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm - Trigger Scale Up when CPU > 12%
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.vpc_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 # check 2 times before trigger
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
}

# ===================================================================
# Auto Scaling Policies - Scale Down
# ===================================================================

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.vpc_name}-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.webapp.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm - Trigger Scale Down when CPU < 8%
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.vpc_name}-cpu-low"
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
}

# ===================================================================
# Outputs
# ===================================================================

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.webapp.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.webapp.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.webapp.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.webapp.latest_version
}
