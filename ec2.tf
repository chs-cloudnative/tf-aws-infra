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

  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  disable_api_termination = false

  tags = {
    Name = "${var.vpc_name}-webapp-instance"
  }
}

# Output the public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}