# 1. Deploy the Networking Foundation
module "networking" {
  source = "./modules/networking"
}

# 2. Deploy the ECS Cluster and Application
module "ecs" {
  source = "./modules/ecs"

  # We grab the outputs from the networking module and pass them as inputs to ECS!
  vpc_id         = module.networking.vpc_id
  public_subnets = module.networking.public_subnets
  ecs_sg_id      = module.networking.ecs_sg_id
}