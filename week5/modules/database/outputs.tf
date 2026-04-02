output "db_endpoint" { value = aws_db_instance.wordpress_db.endpoint }
output "db_name" { value = aws_db_instance.wordpress_db.db_name }
output "db_username" { value = aws_db_instance.wordpress_db.username }
output "db_secret_arn" { value = aws_db_instance.wordpress_db.master_user_secret[0].secret_arn }
output "db_instance_id" { value = aws_db_instance.wordpress_db.id }