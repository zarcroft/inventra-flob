# module networking — à créer par les étudiants
#
# Ressources attendues :
#   - aws_vpc
#   - aws_subnet (public x2, privé x2 dans 2 AZ différentes)
#   - aws_internet_gateway + aws_route_table (public)
#   - aws_db_subnet_group (pour RDS — utilise les subnets privés)
#
# Variables d'entrée minimales :
#   name_prefix, vpc_cidr, public_subnet_cidrs,
#   private_subnet_cidrs, availability_zones
#
# Outputs attendus :
#   vpc_id, public_subnet_ids, private_subnet_ids, db_subnet_group_name
