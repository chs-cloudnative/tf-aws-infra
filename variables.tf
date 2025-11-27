# -------------------------------------------------------------------
# AWS 基本設定變數
# -------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use for authentication"
  default     = "dev"
}

# -------------------------------------------------------------------
# VPC 網路設定變數
# -------------------------------------------------------------------

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"

  # 預設創建 3 個 public subnets 每個 subnet 有 256 個 IP（/24 = 後 8 位可變）
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

# -------------------------------------------------------------------
# 命名相關變數
# -------------------------------------------------------------------

# VPC 名稱
variable "vpc_name" {
  type        = string
  description = "Name tag for VPC"
  default     = "csye6225-vpc"
}

# 環境名稱（例如：dev, demo, prod）
variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, demo, prod)"
  default     = "dev"
}

# EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
  default     = "csye6225-keypair"
}

# -------------------------------------------------------------------
# RDS 相關變數
# -------------------------------------------------------------------

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
  default     = "csye6225"
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "csye6225"
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
  # 注意：實際使用時應該從環境變數或 Terraform Cloud 設定
}

# -------------------------------------------------------------------
# Domain Name
# -------------------------------------------------------------------

variable "domain_name" {
  type        = string
  description = "Domain name for Route 53 A record"
  default     = "dev.chs4150.me"
}