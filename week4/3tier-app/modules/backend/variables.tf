variable "vpc_name" {
  description = "Name tag prefix for backend resources"
  type        = string
  default     = "cl-01"
}

variable "private_app_subnet_ids" {
  description = "List of private subnet IDs for the backend application"
  type        = list(string)
}

variable "backend_sg_id" {
  description = "Security Group ID for the backend EC2 instance"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name for the backend EC2"
  type        = string
}

variable "db_endpoint" {
  description = "Aurora database writer endpoint"
  type        = string
}

variable "db_name" {
  description = "Aurora database name"
  type        = string
}
