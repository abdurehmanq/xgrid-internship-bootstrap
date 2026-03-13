variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "The Security Group ID for the ECS EC2 instances"
  type        = string
}