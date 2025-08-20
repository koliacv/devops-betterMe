# BetterMe DevOps Test - Main Terraform Configuration
# This file orchestrates all modules to create EKS infrastructure

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Local variables
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks-cluster"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "betterme-devops-test"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  cluster_name = local.cluster_name

  # AWS region for configuration
  aws_region = var.region

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  database_subnets           = module.vpc.database_subnets
  database_subnet_group_name = module.vpc.database_subnet_group_name
  database_security_group_id = module.security.database_security_group_id

  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  db_engine            = var.db_engine
  db_engine_version    = var.db_engine_version

  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot

  tags = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_name    = local.cluster_name
  cluster_version = var.eks_version

  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  public_subnets       = module.vpc.public_subnets
  eks_service_role_arn = module.security.eks_service_role_arn
  eks_node_role_arn    = module.security.eks_node_role_arn

  node_instance_types   = var.node_instance_types
  node_desired_capacity = var.node_desired_capacity
  node_max_capacity     = var.node_max_capacity
  node_min_capacity     = var.node_min_capacity
  ami_type              = var.ami_type

  # Database configuration for Kubernetes secrets
  db_host     = module.rds.db_endpoint
  db_name     = module.rds.db_name
  db_username = module.rds.db_username
  db_password = module.rds.db_password

  # AWS configuration for application
  aws_region = var.region

  # Optional AWS credentials for traditional authentication (fallback for IRSA)
  aws_access_key_id     = module.security.s3_user_access_key_id
  aws_secret_access_key = module.security.s3_user_secret_access_key

  # S3 configuration for application
  public_bucket_url   = "https://${module.s3.public_bucket_name}.s3.amazonaws.com"
  private_bucket_url  = "https://${module.s3.private_bucket_name}.s3.amazonaws.com"
  public_bucket_name  = module.s3.public_bucket_name
  private_bucket_name = module.s3.private_bucket_name

  tags = local.common_tags
}
