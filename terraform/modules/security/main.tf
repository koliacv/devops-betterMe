# Security Module - Main Configuration
# Creates IAM roles and security groups for EKS infrastructure

# Local variables for naming and tagging consistency
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standard tags with Name field
  common_tags = merge(var.tags, {
    Module = "security"
  })
}

# Data sources for IAM policy documents
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EKS Service Role
resource "aws_iam_role" "eks_service_role" {
  name               = "${local.name_prefix}-eks-service-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-service-role"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_service_role.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_service_role.name
}

# EKS Node Group Role
resource "aws_iam_role" "eks_node_role" {
  name               = "${local.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role_policy.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Additional policy for CloudWatch logs (optional, for monitoring)
resource "aws_iam_role_policy_attachment" "eks_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${local.name_prefix}-eks-cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-sg"
  })
}

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${local.name_prefix}-database"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database-sg"
  })
}

# Data sources
data "aws_caller_identity" "current" {}

# EKS cluster data source removed - was causing circular dependency

# Create dedicated IAM user for S3 access
resource "aws_iam_user" "s3_application_user" {
  name = "${var.project_name}-${var.environment}-s3-user"
  path = "/"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-s3-user"
    Purpose     = "Application S3 access"
    Environment = var.environment
  })
}

# Create access keys for the S3 user
resource "aws_iam_access_key" "s3_application_user" {
  user = aws_iam_user.s3_application_user.name
}

# Create IAM policy for S3 access
resource "aws_iam_policy" "s3_application_policy" {
  name        = "${local.name_prefix}-s3-policy"
  description = "Policy for ${var.project_name} application S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = compact([
          var.public_bucket_arn != "" ? var.public_bucket_arn : null,
          var.public_bucket_arn != "" ? "${var.public_bucket_arn}/*" : null,
          var.private_bucket_arn != "" ? var.private_bucket_arn : null,
          var.private_bucket_arn != "" ? "${var.private_bucket_arn}/*" : null
        ])
      }
    ]
  })

  tags = local.common_tags
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "s3_application_user_policy" {
  user       = aws_iam_user.s3_application_user.name
  policy_arn = aws_iam_policy.s3_application_policy.arn
}
