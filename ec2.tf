# Data source to find the latest custom AMI
data "aws_ami" "custom" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["csye6225-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami                         = data.aws_ami.custom.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.application.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # User Data - 在 EC2 啟動時執行
  user_data = templatefile("${path.module}/user-data.sh", {
    db_host     = aws_db_instance.main.address
    db_port     = aws_db_instance.main.port
    db_name     = aws_db_instance.main.db_name
    db_user     = aws_db_instance.main.username
    db_password = var.db_password
    s3_bucket   = aws_s3_bucket.webapp_images.id
    aws_region  = var.aws_region
  })

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  disable_api_termination = false

  tags = {
    Name = "${var.vpc_name}-webapp-instance"
  }

  # 確保 RDS 實例先建立完成
  depends_on = [aws_db_instance.main]
}

# Output the public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}