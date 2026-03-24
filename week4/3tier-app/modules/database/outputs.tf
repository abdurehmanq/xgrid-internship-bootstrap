output "cluster_endpoint" {
  description = "The endpoint for the RDS database"
  value       = aws_db_instance.postgres_db.address 
}

output "database_name" {
  description = "The name of the initial database"
  value       = aws_db_instance.postgres_db.db_name
}
