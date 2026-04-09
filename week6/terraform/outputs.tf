output "wordpress_alb_dns" {
  description = "The DNS name of the ALB to access WordPress"
  value       = module.alb.alb_dns_name
}

output "database_endpoint" {
  description = "The endpoint connection string for RDS"
  value       = module.rds.db_endpoint
}

output "observability_grafana_url" {
  description = "The direct URL to access the live SRE Grafana Dashboards"
  value       = "http://${module.observability.observability_ip}:3000"
}

output "observability_prometheus_url" {
  description = "The direct URL to access the live Prometheus instance"
  value       = "http://${module.observability.observability_ip}:9090"
}

