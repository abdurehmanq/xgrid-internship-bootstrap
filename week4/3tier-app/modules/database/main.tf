# 1. Database Subnet Group 
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.vpc_name}-rds-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = { Name = "${var.vpc_name}-rds-subnet-group" }
}

# 2. Standard Free-Tier Eligible PostgreSQL Instance
resource "aws_db_instance" "postgres_db" {
  identifier                  = "${var.vpc_name}-database"
  engine                      = "postgres"
  instance_class              = "db.t3.micro" 
  allocated_storage           = 20            
  db_name                     = var.db_name
  username                    = var.db_master_username
  manage_master_user_password = true      
  
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids      = [var.database_sg_id]
  
  iam_database_authentication_enabled = true
  skip_final_snapshot                 = true
  publicly_accessible                 = false

  tags = { Name = "${var.vpc_name}-database" }
}
