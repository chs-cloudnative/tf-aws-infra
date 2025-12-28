# =================================================================================
# Main Terraform Configuration
# =================================================================================
# Purpose: 
#   Orchestrate all infrastructure modules for the product-service application
#
# Architecture Overview:
#   1. Networking - VPC, subnets, security groups
#   2. Security - KMS keys, Secrets Manager
#   3. Database - RDS PostgreSQL
#   4. Storage - S3 bucket for product images
#   5. Serverless - SNS topic and Lambda function for email verification
#   6. Compute - EC2 Auto Scaling, Application Load Balancer
#   7. DNS - Route53 (root + dev hosted zones) + Dev A record pointing to ALB
#
# Module Dependencies (Resolved):
#   networking → security → (database, storage, sns) → (lambda, compute) → dns
#
# Notes:
#   - Modules are applied in dependency order automatically
#   - SNS topic policy is in compute module to avoid circular dependency
#   - All resources use consistent naming: {project}-{env}-{resource}
# =================================================================================

# =================================================================================
# Module 1: Networking
# =================================================================================

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# =================================================================================
# Module 2: Security (KMS + Secrets Manager)
# =================================================================================

module "security" {
  source = "./modules/security"

  project_name       = var.project_name
  environment        = var.environment
  mailgun_api_key    = var.mailgun_api_key
  mailgun_domain     = var.mailgun_domain
  kms_secrets_key_id = "" # Placeholder, actual key created within module
}

# =================================================================================
# Module 3: Database (RDS PostgreSQL)
# =================================================================================

module "database" {
  source = "./modules/database"

  project_name               = var.project_name
  environment                = var.environment
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = module.security.db_password
  private_subnet_ids         = module.networking.private_subnet_ids
  database_security_group_id = module.networking.database_security_group_id
  kms_rds_key_arn            = module.security.kms_rds_key_arn
}

# =================================================================================
# Module 4: Storage (S3 Bucket)
# =================================================================================

module "storage" {
  source = "./modules/storage"

  project_name   = var.project_name
  environment    = var.environment
  kms_s3_key_arn = module.security.kms_s3_key_arn
}

# =================================================================================
# Module 5: Serverless - SNS Topic
# =================================================================================

module "sns" {
  source = "./modules/serverless/sns"

  project_name       = var.project_name
  environment        = var.environment
  kms_secrets_key_id = module.security.kms_secrets_key_id
}

# =================================================================================
# Module 6: Compute (EC2, ALB, Auto Scaling)
# =================================================================================
# Note: SNS topic policy is defined here to avoid circular dependency

module "compute" {
  source = "./modules/compute"

  project_name                    = var.project_name
  environment                     = var.environment
  aws_region                      = var.aws_region
  instance_type                   = var.instance_type
  key_name                        = var.key_name
  asg_min_size                    = var.asg_min_size
  asg_max_size                    = var.asg_max_size
  asg_desired_capacity            = var.asg_desired_capacity
  vpc_id                          = module.networking.vpc_id
  public_subnet_ids               = module.networking.public_subnet_ids
  application_security_group_id   = module.networking.application_security_group_id
  load_balancer_security_group_id = module.networking.load_balancer_security_group_id
  rds_address                     = module.database.rds_address
  rds_port                        = module.database.rds_port
  rds_database_name               = module.database.rds_database_name
  rds_username                    = module.database.rds_username
  kms_ebs_key_arn                 = module.security.kms_ebs_key_arn
  kms_s3_key_arn                  = module.security.kms_s3_key_arn
  kms_secrets_key_arn             = module.security.kms_secrets_key_arn
  db_password_secret_arn          = module.security.db_password_secret_arn
  s3_bucket_id                    = module.storage.s3_bucket_id
  s3_bucket_arn                   = module.storage.s3_bucket_arn
  sns_topic_arn                   = module.sns.topic_arn
}

# =================================================================================
# Module 7: Serverless - Lambda Function
# =================================================================================

module "lambda" {
  source = "./modules/serverless/lambda"

  project_name               = var.project_name
  environment                = var.environment
  lambda_runtime             = var.lambda_runtime
  lambda_timeout             = var.lambda_timeout
  lambda_memory_size         = var.lambda_memory_size
  lambda_placeholder_path    = "${path.root}/lambda_placeholder.zip"
  domain_name                = var.domain_name
  sns_topic_arn              = module.sns.topic_arn
  mailgun_api_key_secret_arn = module.security.mailgun_api_key_secret_arn
  mailgun_domain_secret_arn  = module.security.mailgun_domain_secret_arn
  kms_secrets_key_arn        = module.security.kms_secrets_key_arn
}

# =================================================================================
# Module 8: DNS (Route53)
# =================================================================================
# Purpose: DNS management (Dev + Root Hosted Zones)
# Dependencies: compute (for ALB DNS name)
# 
# Architecture:
#   Root Zone (chs4150.me) → Dev Zone (dev.chs4150.me) → ALB
# =================================================================================

# ---------------------------------------------------------------------------------
# Dev DNS - Hosted Zone and Application Records
# ---------------------------------------------------------------------------------

module "dns_dev" {
  source = "./modules/dns/dev"

  dev_domain             = var.domain_name
  load_balancer_dns_name = module.compute.load_balancer_dns_name
  load_balancer_zone_id  = module.compute.load_balancer_zone_id
}

# ---------------------------------------------------------------------------------
# Root DNS - Root Hosted Zone and Subdomain Delegation
# ---------------------------------------------------------------------------------

module "dns_root" {
  source = "./modules/dns/root"

  providers = {
    aws = aws.root  # ← 使用 Root Account provider
  }

  root_domain = "chs4150.me"
  dev_domain  = var.domain_name
  dev_name_servers = module.dns_dev.dev_name_servers  # ← 傳入 Dev NS

  depends_on = [module.dns_dev]
}
