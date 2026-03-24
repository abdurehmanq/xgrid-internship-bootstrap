output "frontend_public_ip" {
  description = "The public IP address of the frontend EC2 instance"
  value       = aws_instance.react_frontend.public_ip
}

output "frontend_public_dns" {
  description = "The public DNS of the frontend EC2 instance"
  value       = aws_instance.react_frontend.public_dns
}