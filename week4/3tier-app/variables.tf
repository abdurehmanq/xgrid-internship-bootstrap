variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1" # Feel free to change to us-east-2, us-west-2, etc.
}

variable "my_ip" {
  description = "Your public IP address to allow access to the frontend (e.g., x.x.x.x/32). Default is open to the world for testing."
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}

