module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "security_groups" {
  source       = "./modules/security_groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
}

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

module "efs" {
  source             = "./modules/efs"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ecs_sg_id          = module.security_groups.ecs_sg_id
}

module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  target_group_arn   = module.alb.target_group_arn
  ecs_sg_id          = module.security_groups.ecs_sg_id
  db_endpoint        = module.rds.db_endpoint
  db_secret_arn      = module.rds.db_secret_arn
  efs_id             = module.efs.efs_id
}

module "observability" {
  source           = "./modules/observability"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]
}

module "lambda_cron" {
  source           = "./modules/lambda_cron"
  project_name     = var.project_name
  observability_ip = module.observability.observability_ip
  smtp_email       = var.smtp_email
  smtp_password    = var.smtp_password
}

