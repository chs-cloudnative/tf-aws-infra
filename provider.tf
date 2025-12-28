# =================================================================================
# Provider Configuration
# =================================================================================
# Purpose:
#   Configure AWS providers for multi-account deployment
#
# Providers:
#   - aws (default): Dev Account - Application resources
#   - aws.root: Root Account - Root DNS management
#
# Architecture:
#   Root Account → Root Hosted Zone (chs4150.me)
#   Dev Account → Dev Hosted Zone + All application resources
#
# Notes:
#   - Requires both 'dev' and 'root' AWS CLI profiles configured
#   - Root provider only used for dns_root module
# =================================================================================

terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# ---------------------------------------------------------------------------------
# Default Provider (Dev Account)
# ---------------------------------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ---------------------------------------------------------------------------------
# Root Account Provider
# ---------------------------------------------------------------------------------

provider "aws" {
  alias   = "root"
  region  = var.aws_region
  profile = "root"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "shared"
      ManagedBy   = "terraform"
    }
  }
}

# ---------------------------------------------------------------------------------
# Random Provider
# ---------------------------------------------------------------------------------

provider "random" {}
