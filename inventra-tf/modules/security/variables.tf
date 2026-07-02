variable "name_prefix" {
  description = "Préfixe utilisé pour nommer toutes les ressources (ex: inventra)"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC (sortie du module networking)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorisé pour le SSH entrant (ex: VOTRE_IP/32)"
  type        = string
}
