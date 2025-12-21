# =================================================================================
# Module: database/variables
# =================================================================================
# Purpose: Input variables for database module
# =================================================================================

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database master username"
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for DB subnet group"
}

variable "database_security_group_id" {
  type        = string
  description = "Database security group ID"
}

variable "kms_rds_key_arn" {
  type        = string
  description = "KMS key ARN for RDS encryption"
}
