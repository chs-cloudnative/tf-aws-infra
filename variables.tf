# =================================================================================
# Global Variables Configuration
# =================================================================================
# Purpose: 
#   Define all global variables used across the infrastructure
#
# Variable Categories:
#   - Project & Environment identification
#   - AWS configuration
#   - Network CIDR blocks  
#   - Resource sizing
#   - External service credentials
#
# Usage:
#   Values are provided via terraform.tfvars or environment-specific .tfvars files
# =================================================================================

# ---------------------------------------------------------------------------------
# Project Configuration
# ---------------------------------------------------------------------------------

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tagging"
  default     = "product-service"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, demo, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "demo", "prod"], var.environment)
    error_message = "Environment must be dev, demo, or prod"
  }
}

# ---------------------------------------------------------------------------------
# AWS Configuration
# ---------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for authentication"
  default     = "dev"
}

# ---------------------------------------------------------------------------------
# Network Configuration
# ---------------------------------------------------------------------------------

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per AZ)"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per AZ)"
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

# ---------------------------------------------------------------------------------
# Compute Configuration
# ---------------------------------------------------------------------------------

variable "instance_type" {
  type        = string
  description = "EC2 instance type for web application"
  default     = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
  default     = "product-service-keypair"
}

variable "asg_min_size" {
  type        = number
  description = "Minimum number of instances in Auto Scaling Group"
  default     = 3
}

variable "asg_max_size" {
  type        = number
  description = "Maximum number of instances in Auto Scaling Group"
  default     = 5
}

variable "asg_desired_capacity" {
  type        = number
  description = "Desired number of instances in Auto Scaling Group"
  default     = 3
}

# ---------------------------------------------------------------------------------
# Database Configuration
# ---------------------------------------------------------------------------------

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage for RDS in GB"
  default     = 20
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "productdb"
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "dbadmin"
}

# ---------------------------------------------------------------------------------
# Domain Configuration
# ---------------------------------------------------------------------------------

variable "domain_name" {
  type        = string
  description = "Domain name for the application"
  default     = "dev.chs4150.me"
}

# ---------------------------------------------------------------------------------
# External Services Configuration
# ---------------------------------------------------------------------------------

variable "mailgun_api_key" {
  type        = string
  description = "Mailgun API key for sending emails"
  sensitive   = true
}

variable "mailgun_domain" {
  type        = string
  description = "Mailgun domain for sending emails"
  default     = "sandboxd8e5f731c5da4cb9bb6d2838bd0d1955.mailgun.org"
}

# ---------------------------------------------------------------------------------
# Lambda Configuration
# ---------------------------------------------------------------------------------

variable "lambda_runtime" {
  type        = string
  description = "Lambda function runtime"
  default     = "python3.11"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 30
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda function memory size in MB"
  default     = 256
}
