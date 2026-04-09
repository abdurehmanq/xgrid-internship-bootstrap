variable "project_name" {}
variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "ecs_sg_id" {}

