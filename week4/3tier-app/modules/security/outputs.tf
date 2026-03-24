output "frontend_sg_id" {
  description = "The ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "backend_sg_id" {
  description = "The ID of the backend security group"
  value       = aws_security_group.backend.id
}

output "database_sg_id" {
  description = "The ID of the database security group"
  value       = aws_security_group.database.id
}

output "backend_iam_profile_name" {
  description = "The name of the IAM instance profile for the backend"
  value       = aws_iam_instance_profile.backend_profile.name
}