# Security Module - Outputs
# Exposes security resources for use by other modules

output "eks_service_role_arn" {
  description = "ARN of the EKS service role"
  value       = aws_iam_role.eks_service_role.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node role"
  value       = aws_iam_role.eks_node_role.arn
}

# ALB Controller role removed for simplicity
# Can be added back if advanced load balancing is needed

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# Optional IAM user for traditional AWS credentials
output "s3_user_access_key_id" {
  description = "Access key ID for S3 application user (optional traditional authentication)"
  value       = aws_iam_access_key.s3_application_user.id
  sensitive   = true
}

output "s3_user_secret_access_key" {
  description = "Secret access key for S3 application user (optional traditional authentication)"
  value       = aws_iam_access_key.s3_application_user.secret
  sensitive   = true
}
