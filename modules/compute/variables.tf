# =================================================================================
# Module: compute/variables
# =================================================================================
# Purpose: Input variables for compute module
# =================================================================================

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "asg_min_size" {
  type        = number
  description = "Auto Scaling Group minimum size"
}

variable "asg_max_size" {
  type        = number
  description = "Auto Scaling Group maximum size"
}

variable "asg_desired_capacity" {
  type        = number
  description = "Auto Scaling Group desired capacity"
}

# Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "application_security_group_id" {
  type        = string
  description = "Application security group ID"
}

variable "load_balancer_security_group_id" {
  type        = string
  description = "Load balancer security group ID"
}

# Database
variable "rds_address" {
  type        = string
  description = "RDS instance address"
}

variable "rds_port" {
  type        = string
  description = "RDS instance port"
}

variable "rds_database_name" {
  type        = string
  description = "RDS database name"
}

variable "rds_username" {
  type        = string
  description = "RDS master username"
}

# Security
variable "kms_ebs_key_arn" {
  type        = string
  description = "KMS key ARN for EBS encryption"
}

variable "kms_s3_key_arn" {
  type        = string
  description = "KMS key ARN for S3 encryption"
}

variable "kms_secrets_key_arn" {
  type        = string
  description = "KMS key ARN for Secrets Manager"
}

variable "db_password_secret_arn" {
  type        = string
  description = "Database password secret ARN"
}

# Storage
variable "s3_bucket_id" {
  type        = string
  description = "S3 bucket name"
}

variable "s3_bucket_arn" {
  type        = string
  description = "S3 bucket ARN"
}

# Serverless
variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for email verification"
}
