# module security — à créer par les étudiants
#
# Ressources attendues :
#   - aws_security_group "frontend" : 80 et 443 depuis 0.0.0.0/0 + SSH depuis allowed_ssh_cidr
#   - aws_security_group "backend"  : 5000 depuis SG frontend + SSH depuis allowed_ssh_cidr
#   - aws_security_group "rds"      : 5432 depuis SG backend UNIQUEMENT (pas d'accès public)
#   - aws_iam_role + aws_iam_instance_profile pour EC2
#     (permissions : SSM Parameter Store + Secrets Manager en lecture)
#
# Variables d'entrée minimales :
#   name_prefix, vpc_id, allowed_ssh_cidr
#
# Outputs attendus :
#   sg_frontend_id, sg_backend_id, sg_rds_id,
#   ec2_instance_profile_name
