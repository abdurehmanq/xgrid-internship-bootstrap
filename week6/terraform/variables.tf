variable "aws_region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name for resources"
  type        = string
  default     = "sre-wp"
}

variable "smtp_email" {
  description = "Optional SMTP email for Lambda to send daily reliability reports"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "Optional SMTP password / app password"
  type        = string
  sensitive   = true
  default     = ""
}

