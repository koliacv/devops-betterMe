# BetterMe DevOps Test - Variables
# This file defines all input variables for the infrastructure

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "betterme-test"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster (optional - will be generated if not provided)"
  type        = string
  default     = ""
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

# EKS Configuration
variable "eks_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t4g.micro"] # Changed from t3.micro to t4g.micro for ARM64 architecture
}

variable "node_desired_capacity" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_min_capacity" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 2 # Changed from 1 to 2 for HA
}

variable "ami_type" {
  description = "AMI type for EKS node group (AL2_x86_64 or AL2_ARM_64)"
  type        = string
  default     = "AL2_ARM_64" # ARM64 for t4g instances
}

# RDS Configuration
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
  default     = "betterme"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "postgres"
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

