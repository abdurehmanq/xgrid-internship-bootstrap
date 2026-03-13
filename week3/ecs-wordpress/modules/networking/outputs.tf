output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

output "ecs_sg_id" {
  description = "The ID of the security group for ECS"
  value       = aws_security_group.ecs_sg.id
}