variable "name_prefix" {
  description = "Préfixe utilisé pour nommer toutes les ressources (ex: inventra)"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Nom du db subnet group (sortie du module networking)"
  type        = string
}

variable "sg_rds_id" {
  description = "ID du security group RDS (sortie du module security)"
  type        = string
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "inventra"
}

variable "db_username" {
  description = "Nom d'utilisateur admin de la base"
  type        = string
  default     = "inventra_user"
}

variable "db_password" {
  description = "Mot de passe de la base (sensible, jamais outputté)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}
