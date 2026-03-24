variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC and security groups"
  type        = string
  default     = "cl-01"
}

variable "allowed_frontend_ips" {
  description = "List of IP addresses allowed to access the frontend presentation tier"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this in main.tf to your specific IP for stricter security
}
