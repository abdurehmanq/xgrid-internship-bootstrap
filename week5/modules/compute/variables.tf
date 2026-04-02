variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" {}
variable "ec2_sg_id" {}
variable "efs_sg_id" {}
variable "db_endpoint" {}
variable "db_name" {}
variable "db_username" {}
variable "db_secret_arn" {}
variable "instance_profile_name" {}