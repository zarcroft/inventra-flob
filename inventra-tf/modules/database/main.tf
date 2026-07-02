# ─── Instance RDS PostgreSQL ─────────────────────────────────────────
resource "aws_db_instance" "main" {
  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type       = "gp2"
  storage_encrypted  = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.sg_rds_id]

  # Pas d'endpoint public : accessible uniquement depuis l'intérieur du VPC
  publicly_accessible = false

  multi_az                 = false # TP uniquement — mettre true en vraie prod
  backup_retention_period  = 1
  skip_final_snapshot      = true  # facilite la destruction en TP

  tags = {
    Name = "${var.name_prefix}-db"
  }
}

# ─── Paramètre SSM : URL de connexion complète, chiffrée ────────────
resource "aws_ssm_parameter" "db_url" {
  name = "/${var.name_prefix}/db_url"
  type = "SecureString"

  value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"

  tags = {
    Name = "${var.name_prefix}-db-url"
  }
}
