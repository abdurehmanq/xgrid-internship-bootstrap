# 1. Virtual Private Cloud (VPC) - The foundation of our network
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "week3-ecs-vpc"
  }
}

# 2. Internet Gateway - Connects our VPC to the outside world
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "week3-igw"
  }
}

# 3. Public Subnets - Placed in two different Availability Zones for High Availability (HA)
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "us-east-1a" # Adjust if your default region is different
  map_public_ip_on_launch = true         # Automatically gives our EC2 instance a public IP

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "us-east-1b" # A different AZ to ensure HA
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

# 4. Route Table - Tells our subnets how to reach the internet via the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 5. Route Table Associations - Links our subnets to the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Security Group - Our Firewall rules
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-wordpress-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow incoming web traffic (WordPress)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming SSH traffic (for debugging if needed)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic (so our server can download WordPress/updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}