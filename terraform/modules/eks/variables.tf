# EKS Module - Variables
# Defines input variables for the EKS module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "eks_service_role_arn" {
  description = "ARN of the EKS service role"
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN of the EKS node role"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_capacity" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 4
}

variable "node_min_capacity" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    "project"     = "betterme-test"
    "environment" = "test"
  }
}

variable "disk_size" {
  description = "Disk size for EKS node group"
  type        = number
  default     = 20
}

variable "ami_type" {
  description = "AMI type for EKS node group"
  type        = string
  default     = "AL2_ARM_64" # Changed from AL2_x86_64 to AL2_ARM_64 for ARM64 architecture
}

# Database variables for Kubernetes secrets
variable "db_host" {
  description = "Database host for Kubernetes secret"
  type        = string
}

variable "db_name" {
  description = "Database name for Kubernetes secret"
  type        = string
}

variable "db_username" {
  description = "Database username for Kubernetes secret"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password for Kubernetes secret"
  type        = string
  sensitive   = true
}

# AWS credentials for Kubernetes secrets (optional - IRSA is preferred)
variable "aws_access_key_id" {
  description = "AWS access key ID for Kubernetes secret (optional, use IRSA instead for better security)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for Kubernetes secret (optional, use IRSA instead for better security)"
  type        = string
  default     = ""
  sensitive   = true
}

# Application configuration variables
variable "aws_region" {
  description = "AWS region for application configuration"
  type        = string
}

variable "public_bucket_url" {
  description = "Public S3 bucket URL"
  type        = string
}

variable "private_bucket_url" {
  description = "Private S3 bucket URL"
  type        = string
}

variable "public_bucket_name" {
  description = "Public S3 bucket name"
  type        = string
}

variable "private_bucket_name" {
  description = "Private S3 bucket name"
  type        = string
}
