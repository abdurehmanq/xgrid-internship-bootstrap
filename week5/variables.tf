variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "sns_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}