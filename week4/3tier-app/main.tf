# 1. Networking Module
module "networking" {
  source = "./modules/networking"

  vpc_cidr                 = "10.0.0.0/16"
  public_subnets_cidr      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnets_cidr = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnets_cidr  = ["10.0.21.0/24", "10.0.22.0/24"]
  availability_zones       = ["${var.aws_region}a", "${var.aws_region}b"]
}

# 2. Security Module
module "security" {
  source = "./modules/security"

  vpc_id               = module.networking.vpc_id
  allowed_frontend_ips = var.my_ip
}

# 3. Database Module
module "database" {
  source = "./modules/database"
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  database_sg_id        = module.security.database_sg_id
}

# 4. Backend Module (Flask)
module "backend" {
  source = "./modules/backend"

  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  backend_sg_id             = module.security.backend_sg_id
  iam_instance_profile_name = module.security.backend_iam_profile_name
  db_endpoint               = module.database.cluster_endpoint
  db_name                   = module.database.database_name
  db_secret_arn             = module.database.db_secret_arn
}

# 5. Frontend Module (React + Nginx)
module "frontend" {
  source = "./modules/frontend"

  public_subnet_ids  = module.networking.public_subnet_ids
  frontend_sg_id     = module.security.frontend_sg_id
  backend_private_ip = module.backend.backend_private_ip
}
