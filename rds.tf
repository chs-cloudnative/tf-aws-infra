# -------------------------------------------------------------------
# RDS Subnet Group
# -------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.vpc_name}-db-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = aws_subnet.private[*].id

  tags = {
    Name        = "${var.vpc_name}-db-subnet-group"
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# RDS Parameter Group
# -------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {
  name   = "${var.vpc_name}-postgres-params"
  family = "postgres16" # PostgreSQL 16 family

  # 設定字元編碼
  parameter {
    name  = "client_encoding"
    value = "UTF8"
  }

  # 設定時區
  parameter {
    name  = "timezone"
    value = "UTC"
  }

  tags = {
    Name        = "${var.vpc_name}-postgres-params"
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# RDS Instance
# -------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier     = var.db_name
  engine         = "postgres"
  engine_version = "16.3" # PostgreSQL 16.3

  instance_class    = var.db_instance_class # 容量和記憶體大小: db.t3.micro
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2" # 指定儲存類型，gp2 是通用型 SSD。

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  publicly_accessible = false
  skip_final_snapshot = true # 刪除實例時跳過創建最終快照(通常在dev中使用)

  # 備份設定
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # 效能監控
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.vpc_name}-postgres-rds"
    Environment = var.environment
  }
}

# ===================================================================
# RDS Outputs
# ===================================================================

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS instance address (hostname)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}