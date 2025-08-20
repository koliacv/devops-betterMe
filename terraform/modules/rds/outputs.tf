# RDS Module - Outputs
# Exposes RDS database information for use by other modules

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "RDS instance endpoint (hostname only, without port)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_password" {
  description = "Database password"
  value       = local.db_password
  sensitive   = true
}

output "db_instance_engine" {
  description = "Engine of the database"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "Engine version of the database"
  value       = aws_db_instance.main.engine_version
}

