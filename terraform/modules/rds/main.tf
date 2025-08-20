# RDS Module - Main Configuration
# Creates PostgreSQL RDS instance

# Local variables for naming and tagging consistency
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  db_password = "betterme123456"
  common_tags = merge(var.tags, {
    Module      = "rds"
    Environment = var.environment
  })
}

# Create RDS parameter group
resource "aws_db_parameter_group" "main" {
  family = "postgres16" # PostgreSQL 16.x family
  name   = "${var.project_name}-${var.environment}-db-params"

  # PostgreSQL Engine Parameters (Dynamic - can be applied immediately)
  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = "170" # 170ms to only capture long running queries
    apply_method = "immediate"
  }

  parameter {
    name         = "log_checkpoints"
    value        = "on"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_connections"
    value        = "on"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = "on"
    apply_method = "immediate"
  }
  tags = var.tags
}

# Create RDS instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  # Engine settings
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage settings
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  # Database settings
  db_name  = var.db_name
  username = var.db_username
  password = local.db_password
  port     = 5432

  # Network settings
  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Monitoring disabled for cost optimization in environment
  monitoring_interval = 0
  # Performance Insights disabled for cost optimization
  performance_insights_enabled = false
  # Deletion settings for development
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-postgres"
  })
}
