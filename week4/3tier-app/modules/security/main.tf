# 1. Frontend Security Group (Presentation Tier)
resource "aws_security_group" "frontend" {
  name        = "${var.vpc_name}-frontend-sg"
  description = "Allow HTTP traffic to the React/Nginx frontend"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTP from allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_frontend_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-frontend-sg" }
}

# 2. Backend Security Group (Application Tier)
resource "aws_security_group" "backend" {
  name        = "${var.vpc_name}-backend-sg"
  description = "Allow traffic from frontend to Flask backend"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Flask API port from Frontend"
    from_port       = 5000 # Default Flask port
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    description     = "Allow SSH from Frontend Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-backend-sg" }
}

# 3. Database Security Group (Data Tier)
resource "aws_security_group" "database" {
  name        = "${var.vpc_name}-database-sg"
  description = "Allow traffic from backend to Aurora Database"
  vpc_id      = var.vpc_id

  # Existing rule for Backend
  ingress {
    description     = "PostgreSQL access from Backend"
    from_port       = 5432 
    to_port         = 5432 
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  # Existing rule for Frontend Setup Script
  ingress {
    description     = "PostgreSQL access from Frontend for setup script"
    from_port       = 5432 
    to_port         = 5432 
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.vpc_name}-database-sg" }
}

# 4. IAM Role for Backend EC2 Instance (DB Access & CloudWatch)
resource "aws_iam_role" "backend_role" {
  name = "${var.vpc_name}-backend-role"

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
}

# Attach policy to allow pushing metrics to CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM policy so you can securely connect to the private EC2 without SSH/Bastion
resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for RDS IAM Authentication
resource "aws_iam_policy" "rds_iam_auth" {
  name        = "${var.vpc_name}-rds-iam-auth"
  description = "Allow EC2 to connect to RDS via IAM"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = ["arn:aws:rds-db:*:*:dbuser:*/backend_user"] 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_iam_auth_attach" {
  role       = aws_iam_role.backend_role.name
  policy_arn = aws_iam_policy.rds_iam_auth.arn
}

# Instance Profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "backend_profile" {
  name = "${var.vpc_name}-backend-profile"
  role = aws_iam_role.backend_role.name
}

# =========================================================
# NEW: Allow Backend to read from AWS Secrets Manager
# =========================================================
resource "aws_iam_role_policy" "backend_secrets_policy" {
  name = "${var.vpc_name}-backend-secrets-policy"
  role = aws_iam_role.backend_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = "*" # Allows the backend to read the secret
    }]
  })
}
