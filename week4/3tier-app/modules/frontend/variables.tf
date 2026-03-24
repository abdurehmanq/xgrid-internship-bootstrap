variable "vpc_name" {
  description = "Name tag prefix for frontend resources"
  type        = string
  default     = "cl-01"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the frontend application"
  type        = list(string)
}

variable "frontend_sg_id" {
  description = "Security Group ID for the frontend EC2 instance"
  type        = string
}

variable "backend_private_ip" {
  description = "Private IP address of the backend EC2 instance for Nginx reverse proxy"
  type        = string
}