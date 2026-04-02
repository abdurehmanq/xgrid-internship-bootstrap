output "wordpress_url" {
  description = "The URL of the Load Balancer to access WordPress"
  value       = "http://${module.compute.alb_dns_name}"
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master password"
  value       = module.database.db_secret_arn
}