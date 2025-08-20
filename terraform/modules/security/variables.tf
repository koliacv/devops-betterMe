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

# S3 Bucket ARNs for IAM policy creation
variable "public_bucket_arn" {
  description = "ARN of the public S3 bucket"
  type        = string
  default     = ""
}

variable "private_bucket_arn" {
  description = "ARN of the private S3 bucket"
  type        = string
  default     = ""
}
