# ─────────────────────────────────────────────────────────────────────
# variables.tf — Toutes les variables d'entrée du projet Inventra
# Ce fichier vous est fourni complet. Ne le modifiez pas.
# Renseignez vos valeurs dans terraform.tfvars (à créer).
# ─────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "Région AWS cible"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Préfixe utilisé pour nommer toutes les ressources"
  type        = string
  default     = "inventra"
}

variable "vpc_cidr" {
  description = "Plage CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs des sous-réseaux publics (frontend + bastion)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs des sous-réseaux privés (RDS)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "instance_type_frontend" {
  description = "Type d'instance EC2 pour le frontend"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_backend" {
  description = "Type d'instance EC2 pour le backend API"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Nom de la paire de clés SSH EC2 (doit exister dans le compte AWS)"
  type        = string
}

variable "db_instance_class" {
  description = "Classe d'instance RDS PostgreSQL"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Nom de la base de données PostgreSQL"
  type        = string
  default     = "inventra"
}

variable "db_username" {
  description = "Nom d'utilisateur PostgreSQL"
  type        = string
  default     = "inventra_user"
  sensitive   = true
}

variable "db_password" {
  description = "Mot de passe PostgreSQL — ne jamais écrire en clair dans un fichier commité"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorisé à se connecter en SSH (votre IP publique — ex: '82.x.x.x/32')"
  type        = string
}

variable "alert_email" {
  description = "Adresse e-mail pour les notifications CloudWatch"
  type        = string
}

variable "ami_id" {
  description = "AMI Amazon Linux 2023 dans eu-west-1 (à vérifier : aws ec2 describe-images ...)"
  type        = string
  default     = "ami-0c1c30571d2dae5c9" # Amazon Linux 2023 eu-west-1 (vérifier avant deploy)
}
