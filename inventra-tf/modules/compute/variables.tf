variable "name_prefix" {
  description = "Préfixe utilisé pour nommer toutes les ressources (ex: inventra)"
  type        = string
}

variable "aws_region" {
  description = "Région AWS (nécessaire pour l'appel aws ssm get-parameter dans user_data)"
  type        = string
}

variable "instance_type_frontend" {
  description = "Type d'instance EC2 pour le frontend Nginx"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_backend" {
  description = "Type d'instance EC2 pour le backend Flask"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Nom de la paire de clés EC2 (créée manuellement dans la console)"
  type        = string
}

variable "subnet_id_frontend" {
  description = "ID du subnet public pour le frontend"
  type        = string
}

variable "subnet_id_backend" {
  description = "ID du subnet public pour le backend"
  type        = string
}

variable "sg_frontend_id" {
  description = "ID du security group frontend"
  type        = string
}

variable "sg_backend_id" {
  description = "ID du security group backend"
  type        = string
}

variable "instance_profile_name" {
  description = "Nom de l'instance profile IAM (lecture SSM/Secrets Manager)"
  type        = string
}

variable "db_ssm_path" {
  description = "Chemin du paramètre SSM contenant l'URL de connexion complète"
  type        = string
}

# ─── Chemins vers les fichiers applicatifs à embarquer dans user_data ─
# Adaptez ces chemins à l'arborescence réelle de votre dépôt.
variable "app_py_path" {
  description = "Chemin local vers backend/app.py"
  type        = string
}

variable "models_py_path" {
  description = "Chemin local vers backend/models.py"
  type        = string
}

variable "index_html_path" {
  description = "Chemin local vers frontend/index.html"
  type        = string
}

variable "style_css_path" {
  description = "Chemin local vers frontend/style.css"
  type        = string
}

variable "app_js_path" {
  description = "Chemin local vers frontend/app.js"
  type        = string
}

variable "create_frontend_eip" {
  description = "Créer une IP publique fixe (Elastic IP) pour le frontend"
  type        = bool
  default     = true
}
