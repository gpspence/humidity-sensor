module "ssm" {
  source       = "./modules/ssm"
  project_name = var.project_name
  environment  = var.environment
  secrets      = local.secrets
}
