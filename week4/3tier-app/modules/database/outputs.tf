output "cluster_endpoint" {
  description = "The endpoint for the RDS database"
  value       = aws_db_instance.postgres_db.address 
}

output "database_name" {
  description = "The name of the initial database"
  value       = aws_db_instance.postgres_db.db_name
}

# This grabs the randomly generated secret ARN directly from RDS
output "db_secret_arn" {
  description = "The ARN of the RDS-managed Secrets Manager secret"
  value       = aws_db_instance.postgres_db.master_user_secret[0].secret_arn
}
