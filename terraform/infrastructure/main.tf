module "vpc" {
  source      = "./vpc"
  aws_region  = var.aws_region
  environment = var.environment
}

module "security_groups" {
  source      = "./security_groups"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "alb" {
  source                = "./alb"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  environment           = var.environment
  alb_security_group_id = module.security_groups.alb_security_group_id
}

module "ec2" {
  source               = "./ec2"
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_id    = module.security_groups.ec2_security_group_id
  environment          = var.environment
  app_image            = var.app_image
  db_password          = var.db_password
  alb_target_group_arn = module.alb.alb_target_group_arn
}