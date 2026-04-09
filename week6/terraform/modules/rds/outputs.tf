output "db_endpoint" {
  value = aws_db_instance.wordpress.endpoint
}

output "db_secret_arn" {
  description = "The ARN mapping to the Secrets Manager vault containing the password"
  value       = aws_secretsmanager_secret.db_secret.arn
}

