output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs des subnets publics, dans l'ordre [frontend, backend]"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des subnets privés (RDS)"
  value       = aws_subnet.private[*].id
}

output "db_subnet_group_name" {
  description = "Nom du db subnet group, à passer au module database"
  value       = aws_db_subnet_group.main.name
}
