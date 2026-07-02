output "frontend_public_ip" {
  description = "IP publique du frontend (EIP si activé, sinon IP publique auto)"
  value       = var.create_frontend_eip ? aws_eip.frontend[0].public_ip : aws_instance.frontend.public_ip
}

output "backend_private_ip" {
  description = "IP privée du backend (utilisée par le proxy Nginx du frontend)"
  value       = aws_instance.backend.private_ip
}

output "frontend_url" {
  description = "URL complète pour accéder à l'application"
  value       = "http://${var.create_frontend_eip ? aws_eip.frontend[0].public_ip : aws_instance.frontend.public_ip}"
}

output "backend_instance_id" {
  description = "ID de l'instance backend (utilisé par le module monitoring)"
  value       = aws_instance.backend.id
}

output "frontend_instance_id" {
  description = "ID de l'instance frontend (utilisé par le module monitoring)"
  value       = aws_instance.frontend.id
}
