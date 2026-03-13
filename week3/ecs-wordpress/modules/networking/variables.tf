# The IP range for our entire VPC
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

# The IP range for our first public subnet
variable "public_subnet_a_cidr" {
  type        = string
  description = "CIDR block for public subnet in AZ A"
  default     = "10.0.1.0/24"
}

# The IP range for our second public subnet (for High Availability)
variable "public_subnet_b_cidr" {
  type        = string
  description = "CIDR block for public subnet in AZ B"
  default     = "10.0.2.0/24"
}