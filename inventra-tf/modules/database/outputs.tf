output "db_endpoint" {
  description = "Endpoint (hôte) de l'instance RDS"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port de l'instance RDS"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.main.db_name
}

output "db_identifier" {
  description = "Identifiant de l'instance RDS (utilisé par le module monitoring)"
  value       = aws_db_instance.main.identifier
}

output "db_connection_ssm_path" {
  description = "Chemin du paramètre SSM contenant l'URL de connexion complète (SecureString)"
  value       = aws_ssm_parameter.db_url.name
}

# ⚠️ Volontairement absent : aucun output de db_password ou de l'URL
# en clair. Le mot de passe reste uniquement dans var.db_password et
# dans la valeur chiffrée du paramètre SSM ci-dessus.
