variable "name_prefix" {
  description = "Préfixe utilisé pour nommer toutes les ressources (ex: inventra)"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC (ex: 10.0.0.0/16)"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Liste des CIDRs des subnets publics (frontend, backend). 2 éléments attendus."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "public_subnet_cidrs doit contenir exactement 2 CIDRs (frontend, backend)."
  }
}

variable "private_subnet_cidrs" {
  description = "Liste des CIDRs des subnets privés (RDS). 2 éléments attendus."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "private_subnet_cidrs doit contenir exactement 2 CIDRs."
  }
}

variable "availability_zones" {
  description = "Liste des AZ à utiliser, une par subnet public et une par subnet privé. 2 éléments attendus."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "availability_zones doit contenir exactement 2 AZ."
  }
}