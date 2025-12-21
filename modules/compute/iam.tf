# =================================================================================
# Module: compute/iam
# =================================================================================
# Purpose: 
#   IAM role and policies for EC2 instances
#
# Role:
#   - EC2 service can assume this role
#   - Attached to instances via Instance Profile
#
# Policies:
#   1. S3 Access - Upload/download product images
#   2. Secrets Manager - Retrieve RDS password at launch
#   3. SNS Publish - Send user verification events
#   4. CloudWatch Agent - Send logs and metrics
#
# Security:
#   - Least privilege principle
#   - Scoped to specific resources
#   - KMS permissions via service conditions
#
# Notes:
#   - Instance Profile is the entity EC2 actually uses
#   - Role defines what permissions the instance has
# =================================================================================

# ---------------------------------------------------------------------------------
# IAM Role for EC2 Instances
# ---------------------------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
    Service     = "EC2"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------------
# IAM Instance Profile
# ---------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-profile"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# =================================================================================
# IAM Policies
# =================================================================================

# ---------------------------------------------------------------------------------
# Policy: S3 Access for Product Images
# ---------------------------------------------------------------------------------

resource "aws_iam_role_policy" "s3_access" {
  name = "${var.project_name}-${var.environment}-s3-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_s3_key_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------------
# Policy: Secrets Manager Access for RDS Password
# ---------------------------------------------------------------------------------

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-${var.environment}-secrets-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.db_password_secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_secrets_key_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------------
# Policy: SNS Publish for User Verification
# ---------------------------------------------------------------------------------

resource "aws_iam_role_policy" "sns_publish" {
  name = "${var.project_name}-${var.environment}-sns-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:GetTopicAttributes"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_secrets_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "sns.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------------
# Policy: CloudWatch Agent (AWS Managed)
# ---------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
