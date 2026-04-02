resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "wp-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = { Name = "wp-rds-subnet-group" }
}

resource "aws_db_instance" "wordpress_db" {
  identifier                  = "wordpress-db"
  allocated_storage           = 20
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  db_name                     = "wordpressdb"
  username                    = "admin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids      = [var.rds_sg_id]
  skip_final_snapshot         = true
  multi_az                    = false
}