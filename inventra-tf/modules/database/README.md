# module database — à créer par les étudiants
#
# Ressources attendues :
#   - aws_db_instance (PostgreSQL 15, db.t3.micro, stockage gp2 20 Go)
#     • multi_az           = false (formation)
#     • skip_final_snapshot = true  (facilite la destruction en TP)
#     • storage_encrypted  = true   (bonne pratique)
#     • backup_retention_period = 1
#   - aws_ssm_parameter pour stocker l'URL de connexion
#     (jamais le mot de passe en clair dans les outputs Terraform)
#
# Variables d'entrée minimales :
#   name_prefix, db_subnet_group_name, sg_rds_id,
#   db_name, db_username, db_password, db_instance_class
#
# Outputs attendus :
#   db_endpoint, db_port, db_name,
#   db_connection_ssm_path (le path du paramètre SSM, pas le mot de passe)
#
# ⚠️  Ne pas outputter db_password — même en sensitive = true,
#     la valeur reste dans le tfstate. Utilisez SSM/Secrets Manager.
