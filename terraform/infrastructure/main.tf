module "vpc" {
  source      = "./modules/vpc"
  aws_region  = var.aws_region
  environment = var.environment
}

module "security_groups" {
  source      = "./modules/security_groups"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "alb" {
  source                = "./modules/alb"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  environment           = var.environment
  alb_security_group_id = module.security_groups.alb_security_group_id
}

module "ec2" {
  source               = "./modules/ec2"
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_id    = module.security_groups.ec2_security_group_id
  environment          = var.environment
  app_image            = var.app_image
  db_password          = var.db_password
  db_name = var.db_name
  db_user = var.db_user
  alb_target_group_arn = module.alb.alb_target_group_arn
}