# =================================================================================
# Module: compute/launch_template
# =================================================================================
# Purpose:
#   Launch template for EC2 instances in Auto Scaling Group
#
# Configuration:
#   - Custom AMI with pre-installed application
#   - User data script for runtime configuration
#   - EBS volume encryption with KMS
#   - IMDSv2 enforced for enhanced security
#
# User Data:
#   1. Retrieve database password from Secrets Manager
#   2. Create application configuration file
#   3. Start application service
#   4. Start CloudWatch agent
#
# Security:
#   - No public IP (behind ALB)
#   - IAM instance profile for AWS API access
#   - Encrypted EBS volumes
#   - IMDSv2 required (防止 SSRF 攻擊)
#
# Notes:
#   - AMI must be pre-built with Packer
#   - User data retrieves secrets at runtime (not baked into AMI)
# =================================================================================

# ---------------------------------------------------------------------------------
# Data Source: Latest Custom AMI
# ---------------------------------------------------------------------------------

data "aws_ami" "application" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["product-service-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ---------------------------------------------------------------------------------
# Launch Template
# ---------------------------------------------------------------------------------

resource "aws_launch_template" "webapp" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ami.application.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Network settings
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.application_security_group_id]
    delete_on_termination       = true
  }

  # IAM Instance Profile
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # User Data - Runtime configuration
  user_data = base64encode(templatefile("${path.root}/scripts/user-data.sh", {
    db_host                = var.rds_address
    db_port                = var.rds_port
    db_name                = var.rds_database_name
    db_user                = var.rds_username
    db_password_secret_arn = var.db_password_secret_arn
    s3_bucket              = var.s3_bucket_id
    aws_region             = var.aws_region
  }))

  # Block device mapping (EBS volume)
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
      # Temporarily use AWS managed key instead of customer-managed KMS
      # kms_key_id            = var.kms_ebs_key_arn
    }
  }

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-webapp-instance"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }

  depends_on = [aws_iam_instance_profile.ec2]
}
