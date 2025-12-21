# =================================================================================
# Global Outputs Configuration
# =================================================================================
# Purpose: 
#   Export important values from all modules for reference and use
#
# Usage:
#   - View outputs: terraform output
#   - Get specific output: terraform output <output_name>
#   - Use in other Terraform configs or scripts
#
# Categories:
#   - Networking (VPC, Subnets, Security Groups)
#   - Security (KMS Keys, Secrets)
#   - Database (RDS Connection Info)
#   - Storage (S3 Bucket)
#   - Serverless (SNS, Lambda)
#   - Compute (EC2, ALB)
#   - DNS (Domain)
# =================================================================================

# =================================================================================
# Networking Outputs
# =================================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones"
  value       = module.networking.availability_zones
}

output "load_balancer_security_group_id" {
  description = "Load balancer security group ID"
  value       = module.networking.load_balancer_security_group_id
}

output "application_security_group_id" {
  description = "Application security group ID"
  value       = module.networking.application_security_group_id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = module.networking.database_security_group_id
}

# =================================================================================
# Security Outputs
# =================================================================================

output "kms_ebs_key_id" {
  description = "KMS key ID for EBS encryption"
  value       = module.security.kms_ebs_key_id
}

output "kms_rds_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = module.security.kms_rds_key_id
}

output "kms_s3_key_id" {
  description = "KMS key ID for S3 encryption"
  value       = module.security.kms_s3_key_id
}

output "kms_secrets_key_id" {
  description = "KMS key ID for Secrets Manager"
  value       = module.security.kms_secrets_key_id
}

output "db_password_secret_name" {
  description = "Database password secret name"
  value       = module.security.db_password_secret_name
}

# =================================================================================
# Database Outputs
# =================================================================================

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.rds_endpoint
}

output "rds_address" {
  description = "RDS instance address"
  value       = module.database.rds_address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.database.rds_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.database.rds_database_name
}

# =================================================================================
# Storage Outputs
# =================================================================================

output "s3_bucket_id" {
  description = "S3 bucket name"
  value       = module.storage.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.storage.s3_bucket_arn
}

# =================================================================================
# Serverless Outputs
# =================================================================================

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = module.sns.topic_arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = module.sns.topic_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.lambda.function_arn
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

# =================================================================================
# Compute Outputs
# =================================================================================

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = module.compute.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = module.compute.ec2_instance_profile_name
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.autoscaling_group_name
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = module.compute.launch_template_id
}

output "launch_template_latest_version" {
  description = "Launch template latest version"
  value       = module.compute.launch_template_latest_version
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.compute.load_balancer_dns_name
}

output "load_balancer_arn" {
  description = "Application Load Balancer ARN"
  value       = module.compute.load_balancer_arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = module.compute.target_group_arn
}

# =================================================================================
# DNS Outputs
# =================================================================================

output "application_url" {
  description = "Application URL"
  value       = "http://${module.dns.route53_record_fqdn}"
}

output "route53_record_fqdn" {
  description = "Route53 record FQDN"
  value       = module.dns.route53_record_fqdn
}

# =================================================================================
# Summary Output
# =================================================================================

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project     = var.project_name
    environment = var.environment
    region      = var.aws_region
    vpc_cidr    = var.vpc_cidr
    app_url     = "http://${module.dns.route53_record_fqdn}"
  }
}
