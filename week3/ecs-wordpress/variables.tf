variable "aws_region" {
  description = "The AWS region to deploy our infrastructure"
  type        = string
  default     = "us-east-1" # US East (N. Virginia) is the standard for Free Tier
}