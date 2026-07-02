# ─────────────────────────────────────────────────────────────────────
# main.tf — Module root du projet Inventra
#
# Ce fichier est VIDE. Vous devez :
#  1. Créer les fichiers locals.tf et outputs.tf
#  2. Déclarer les appels aux modules que vous aurez écrits
#  3. Enchaîner les outputs d'un module comme inputs du suivant
#
# Ordre suggéré :
#   networking → security → database → compute → monitoring
# ─────────────────────────────────────────────────────────────────────

# TODO : data sources communs
# data "aws_caller_identity" "current" {}
# data "aws_availability_zones" "available" { state = "available" }

# TODO : appel module networking
# module "networking" { ... }

# TODO : appel module security
# module "security" { ... }

# TODO : appel module database
# module "database" { ... }

# TODO : appel module compute
# module "compute" { ... }

# TODO : appel module monitoring
# module "monitoring" { ... }
