output "backend_private_ip" {
  description = "The private IP address of the backend EC2 instance"
  value       = aws_instance.flask_backend.private_ip
}