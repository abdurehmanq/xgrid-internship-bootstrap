variable "project_name" {}
variable "private_subnet_ids" { type = list(string) }
variable "rds_sg_id" {}

# Generate a high-entropy password
resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create the Secret Vault in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name_prefix = "${var.project_name}-rds-password-"
  description = "Master password for RDS WordPress Database"
}

# Store the Secret String
resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = random_password.master_password.result
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "wordpress" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "wordpressdb"
  username               = "admin"
  password               = random_password.master_password.result
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
}

