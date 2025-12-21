# =================================================================================
# Module: compute/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

# ---------------------------------------------------------------------------------
# IAM Outputs
# ---------------------------------------------------------------------------------

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2.arn
}

output "ec2_role_name" {
  description = "EC2 IAM role name"
  value       = aws_iam_role.ec2.name
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2.name
}

# ---------------------------------------------------------------------------------
# Auto Scaling Outputs
# ---------------------------------------------------------------------------------

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.webapp.name
}

output "autoscaling_group_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.webapp.arn
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.webapp.id
}

output "launch_template_latest_version" {
  description = "Launch template latest version"
  value       = aws_launch_template.webapp.latest_version
}

# ---------------------------------------------------------------------------------
# Load Balancer Outputs
# ---------------------------------------------------------------------------------

output "load_balancer_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.webapp.arn
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.webapp.dns_name
}

output "load_balancer_zone_id" {
  description = "Application Load Balancer zone ID (for Route53)"
  value       = aws_lb.webapp.zone_id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.webapp.arn
}
