variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet, utilisé comme préfixe de nommage"
  type        = string
  default     = "inventra"
}

# ─── networking ───────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "Bloc CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs des 2 subnets publics (frontend, backend)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs des 2 subnets privés (RDS)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "2 AZ à utiliser (une par paire de subnets public/privé)"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

# ─── security / accès ─────────────────────────────────────────────
variable "key_pair_name" {
  description = "Nom de la paire de clés EC2 (créée manuellement dans la console)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorisé pour le SSH entrant"
  type        = string
}

# ─── database ──────────────────────────────────────────────────────
variable "db_password" {
  description = "Mot de passe RDS (sensible)"
  type        = string
  sensitive   = true
}

# ─── monitoring ────────────────────────────────────────────────────
variable "alert_email" {
  description = "Email qui reçoit les alertes CloudWatch/SNS"
  type        = string
}

# ─── compute : chemins vers les fichiers applicatifs ────────────────
# Chemins relatifs a la racine inventra-tf/ (là où vous lancez terraform)
variable "app_py_path" {
  description = "Chemin local vers backend/app.py"
  type        = string
  default     = "inventra/backend/app.py"
}

variable "models_py_path" {
  description = "Chemin local vers backend/models.py"
  type        = string
  default     = "inventra/backend/models.py"
}

variable "index_html_path" {
  description = "Chemin local vers frontend/index.html"
  type        = string
  default     = "inventra/frontend/index.html"
}

variable "style_css_path" {
  description = "Chemin local vers frontend/style.css"
  type        = string
  default     = "inventra/frontend/style.css"
}

variable "app_js_path" {
  description = "Chemin local vers frontend/app.js"
  type        = string
  default     = "inventra/frontend/app.js"
}