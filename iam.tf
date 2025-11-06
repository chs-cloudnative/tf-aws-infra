# -------------------------------------------------------------------
# IAM Role for EC2 Instance
# -------------------------------------------------------------------

# EC2 可以擔任的 IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # 指定信任主體
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EC2-CSYE6225-Role"
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# IAM Policy for S3 Access
# -------------------------------------------------------------------

# S3 訪問政策
resource "aws_iam_role_policy" "s3_policy" {
  name = "S3-Access-Policy"
  role = aws_iam_role.ec2_role.id

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
          aws_s3_bucket.webapp_images.arn,
          "${aws_s3_bucket.webapp_images.arn}/*"
        ]
      }
    ]
  })
}

# -------------------------------------------------------------------
# IAM Instance Profile
# -------------------------------------------------------------------

# Instance Profile - 讓 EC2 可以使用 IAM Role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-Instance-Profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "EC2-Instance-Profile"
    Environment = var.environment
  }
}