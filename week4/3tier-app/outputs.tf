output "react_app_url" {
  description = "The public URL to access your React Presentation Tier"
  value       = "http://${module.frontend.frontend_public_dns}"
}

output "react_app_ip" {
  description = "The public IP address to access your React Presentation Tier"
  value       = module.frontend.frontend_public_ip
}

output "aurora_database_endpoint" {
  description = "The internal endpoint of your Aurora Serverless database"
  value       = module.database.cluster_endpoint
}