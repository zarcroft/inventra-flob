module "networking" {
  source = "./modules/networking"

  name_prefix           = var.project_name
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  availability_zones     = var.availability_zones
}

module "security" {
  source = "./modules/security"

  name_prefix      = var.project_name
  vpc_id           = module.networking.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "database" {
  source = "./modules/database"

  name_prefix           = var.project_name
  db_subnet_group_name  = module.networking.db_subnet_group_name
  sg_rds_id             = module.security.sg_rds_id
  db_password           = var.db_password
}

# ─── Modules suivants : à décommenter au fur et à mesure ───────────
# Chaque module dépend des outputs du(des) précédent(s) — voir le
# diagramme de dépendances de l'étape 1.
#
module "compute" {
  source = "./modules/compute"

  name_prefix            = var.project_name
  aws_region             = var.aws_region
  key_pair_name          = var.key_pair_name
  subnet_id_frontend     = module.networking.public_subnet_ids[0]
  subnet_id_backend      = module.networking.public_subnet_ids[1]
  sg_frontend_id         = module.security.sg_frontend_id
  sg_backend_id          = module.security.sg_backend_id
  instance_profile_name  = module.security.ec2_instance_profile_name
  db_ssm_path            = module.database.db_connection_ssm_path

  app_py_path      = var.app_py_path
  models_py_path   = var.models_py_path
  index_html_path  = var.index_html_path
  style_css_path   = var.style_css_path
  app_js_path      = var.app_js_path
}

# ─── Modules suivants : à décommenter au fur et à mesure ───────────
# Chaque module dépend des outputs du(des) précédent(s) — voir le
# diagramme de dépendances de l'étape 1.
#
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix          = var.project_name
  alert_email          = var.alert_email
  backend_instance_id  = module.compute.backend_instance_id
  frontend_instance_id = module.compute.frontend_instance_id
  db_identifier        = module.database.db_identifier
}
