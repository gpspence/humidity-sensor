module "network" {
  source             = "./modules/network"
  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "ssm" {
  source       = "./modules/ssm"
  project_name = var.project_name
  environment  = var.environment
  secrets      = local.secrets
}

module "ec2" {
  source                 = "./modules/ec2"
  project_name           = var.project_name
  environment            = var.environment
  secret_arns            = module.ssm.secret_arns
  vpc_security_group_ids = [module.network.ec2_security_group_id]
  subnet_id              = module.network.subnet_id
}
