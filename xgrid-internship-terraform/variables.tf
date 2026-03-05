variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the existing AWS Key Pair to allow SSH access"
  type        = string
}

variable "tags" {
  description = "Standardized tagging convention for Xgrid resources"
  type        = map(any)
  default = {
    app         = "WordPress"
    created-by  = "Terraform"
    environment = "XLDP - Dev"
    name        = "Abdurehman"
    project     = "Module_Name - XLDP"
    owner       = "abdur.rehman@xgrid.co"
    creator     = "abdur.rehman@xgrid.co"
    team        = "Firebirds"
  }
}
