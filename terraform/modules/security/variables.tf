# Security Module - Variables
# Defines input variables for the security module

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

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default = {
    "project"     = "betterme-test"
    "environment" = "test"
  }
}

# AWS credentials are now automatically generated
# No user-provided credentials needed

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

# S3 Bucket ARNs no longer needed - using AWS managed S3FullAccess policy
