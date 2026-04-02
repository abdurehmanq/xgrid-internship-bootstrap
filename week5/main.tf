module "networking" {
  source = "./modules/networking"
  
  aws_region = var.aws_region
  vpc_cidr   = "10.0.0.0/16"
}

module "security" {
  source = "./modules/security"
  
  vpc_id = module.networking.vpc_id
}

module "database" {
  source = "./modules/database"

  private_subnet_ids = module.networking.private_subnet_ids
  rds_sg_id          = module.security.rds_sg_id
}

module "iam" {
  source = "./modules/iam"

  db_secret_arn = module.database.db_secret_arn
}

module "compute" {
  source = "./modules/compute"

  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_sg_id             = module.security.alb_sg_id
  ec2_sg_id             = module.security.ec2_sg_id
  efs_sg_id             = module.security.efs_sg_id
  db_endpoint           = module.database.db_endpoint
  db_name               = module.database.db_name
  db_username           = module.database.db_username
  db_secret_arn         = module.database.db_secret_arn
  instance_profile_name = module.iam.instance_profile_name
}

module "monitoring" {
  source = "./modules/monitoring"

  aws_region     = var.aws_region
  sns_email      = var.sns_email
  asg_name       = module.compute.asg_name
  alb_arn_suffix = module.compute.alb_arn_suffix
  db_instance_id = module.database.db_instance_id
}