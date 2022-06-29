# VPCの設定
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.service_name}-vpc"
    Service = var.service_name
  }

  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Public Subnetの設定
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.main.id

  cidr_block        = element(var.public_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.service_name}-public-${count.index}"
  }
}

# Private Subnetの設定
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.service_name}-private-${count.index}"
  }
}

# セキュリティグループ
# EC2とELBのSGを併用しているので、プロトコルの指定のみを行う
# 本来であれば、ECS(EC2)用のSGとALBのSGは分けるべき
# ALBのSGもしくはEIPからのアクセスしかできないようにする設定が必要
# alb
resource "aws_security_group" "alb" {
  name   = "alb-security-group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "alb-security-group"
    Service = var.service_name
  }

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# web
resource "aws_security_group" "web" {
  name   = "web-security-group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "web-security-group"
    Service = var.service_name
  }

  ingress {
    from_port       = 0
    to_port         = 80
    protocol        = "TCP"
    security_groups = [
      aws_security_group.alb.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IGWの設定
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.service_name}-vpc-igw"
  }
}

# NAT Gateway
resource "aws_eip" "ngw_eip" {
  count = length(var.ngws)
  vpc = true

  tags = {
    Name = "${var.service_name}-ngw-eip"
  }
}

resource "aws_nat_gateway" "ngw" {
  count = length(var.ngws)
  allocation_id = aws_eip.ngw_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = element(var.ngws, count.index)
  }
}

# ルートテーブルの設定
# Natgatwayとprivate subnet
resource "aws_route_table" "private_route_table" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[count.index].id
  }

  tags = {
    Name = "${var.service_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_subnet" {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Natgatwayとpublic subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.service_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_subnet" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}
