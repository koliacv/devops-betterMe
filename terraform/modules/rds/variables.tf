# RDS Module - Variables
# Defines input variables for the RDS module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "database_subnets" {
  description = "List of database subnet IDs"
  type        = list(string)
}

variable "database_subnet_group_name" {
  description = "Name of the database subnet group (managed by VPC module)"
  type        = string
}

variable "database_security_group_id" {
  description = "ID of the database security group"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS instance (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_engine" {
  description = "Engine of the database"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Engine version of the database"
  type        = string
  default     = "16"
}

variable "deletion_protection" {
  description = "Enable deletion protection for the database"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting the database"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}


