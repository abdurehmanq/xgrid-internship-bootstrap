# 1. VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

# 2. Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.vpc_name}-public-${count.index + 1}" }
}

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnets_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.vpc_name}-private-app-${count.index + 1}" }
}

resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnets_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.vpc_name}-private-db-${count.index + 1}" }
}

# 3. Internet Gateway (For Public Subnets)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.vpc_name}-igw" }
}

# 4. NAT Gateway and Elastic IP (For Private App Subnets)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "${var.vpc_name}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place NAT in the first public subnet
  tags = { Name = "${var.vpc_name}-nat" }
  depends_on    = [aws_internet_gateway.igw]
}

# 5. Route Tables and Associations
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.vpc_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table (App tier goes to NAT)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.vpc_name}-private-app-rt" }
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# Note: The Private DB subnets do not get a NAT route. They remain completely isolated.