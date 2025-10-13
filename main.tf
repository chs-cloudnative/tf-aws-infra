# 獲取指定 region 中所有可用的 Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC（Virtual Private Cloud）
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr # define VPC IP address
  enable_dns_hostnames = true         # 讓 EC2 instances 可以獲得 DNS 名稱
  enable_dns_support   = true         # 讓 VPC 內可以使用 DNS 解析
  tags = {
    Name        = var.vpc_name
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]                     # subnet 的 IP 範圍 依序取得3個
  availability_zone       = data.aws_availability_zones.available.names[count.index] # subnet 依序放入3個 AZ
  map_public_ip_on_launch = true                                                     # 在這個 subnet 啟動的 EC2 會自動分配獲得公開 IP
  tags = {
    Name        = "public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public" # 額外的 Type tag 標記這是 public subnet
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # map_public_ip_on_launch = false（已經是預設值）
  tags = {
    Name        = "private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.environment
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.vpc_name}-public-rt"
    Environment = var.environment
    Type        = "Public"
  }
}

# Public Route
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0" # 0.0.0.0/0 表示「所有 IP 地址」
  gateway_id             = aws_internet_gateway.main.id
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.vpc_name}-private-rt"
    Environment = var.environment
    Type        = "Private"
  }
}

# No Private Route: private route table 沒有指向 IGW 表示無法直接連接到網際網路

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
