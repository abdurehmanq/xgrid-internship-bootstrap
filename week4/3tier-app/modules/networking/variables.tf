variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "cl-01-vpc"
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_app_subnets_cidr" {
  description = "List of CIDR blocks for private application subnets"
  type        = list(string)
}

variable "private_db_subnets_cidr" {
  description = "List of CIDR blocks for private database subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of Availability Zones to use"
  type        = list(string)
}