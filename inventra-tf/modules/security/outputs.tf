output "sg_frontend_id" {
  description = "ID du security group frontend"
  value       = aws_security_group.frontend.id
}

output "sg_backend_id" {
  description = "ID du security group backend"
  value       = aws_security_group.backend.id
}

output "sg_rds_id" {
  description = "ID du security group RDS"
  value       = aws_security_group.rds.id
}

output "ec2_instance_profile_name" {
  description = "Nom de l'instance profile IAM à attacher aux EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}
