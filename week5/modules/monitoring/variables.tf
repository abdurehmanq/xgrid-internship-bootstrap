variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "sns_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "db_instance_id" {
  description = "Identifier of the RDS database instance"
  type        = string
}
