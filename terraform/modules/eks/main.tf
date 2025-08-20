# EKS Module - Main Configuration
# Creates EKS cluster with managed node groups

# Data source for EKS cluster auth
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

# Create EKS cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.eks_service_role_arn

  vpc_config {
    subnet_ids              = concat(var.private_subnets, var.public_subnets)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  # Enable control plane logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # For properly deleting EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_cloudwatch_log_group.eks_cluster_log_group
  ]

  tags = var.tags
}

# CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster_log_group" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 1

  tags = var.tags
}

# OIDC Identity Provider
data "tls_certificate" "eks_cluster_tls" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-oidc"
  })
}

# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.public_subnets # Moved to public subnets to avoid NAT Gateway costs

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  update_config {
    max_unavailable = 1
  }
  # AMI type
  ami_type = var.ami_type
  # Disk size
  disk_size = var.disk_size

  # Labels
  labels = {
    role        = "worker"
    environment = var.environment
  }

  # Taints can be added here if needed
  # taint {
  #   key    = "dedicated"
  #   value  = "worker"
  #   effect = "NO_SCHEDULE"
  # }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group"
  })

  # !!!!!!Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [aws_eks_cluster.main]
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  depends_on = [aws_eks_node_group.main]

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  tags = var.tags
}

# Kubernetes Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.project_name
    labels = {
      name        = var.project_name
      environment = var.environment
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# Database Credentials Secret - REMOVED (using combined DATABASE_URL in ConfigMap instead)

# AWS Credentials Secret (created when access keys are provided)
resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "${var.project_name}-aws-credentials"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    access_key_id     = var.aws_access_key_id
    secret_access_key = var.aws_secret_access_key
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.app_namespace]
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.project_name}-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    aws_region         = var.aws_region
    public_bucket_url  = var.public_bucket_url
    private_bucket_url = var.private_bucket_url
    database_url       = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:5432/${var.db_name}"
  }

  depends_on = [kubernetes_namespace.app_namespace]
}

# IAM Role for Service Account (IRSA) - More secure than access keys
resource "aws_iam_role" "app_service_account_role" {
  name = "${var.project_name}-${var.environment}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks_cluster_oidc.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks_cluster_oidc.url, "https://", "")}:sub" = "system:serviceaccount:${var.project_name}:${var.project_name}-service-account"
            "${replace(aws_iam_openid_connect_provider.eks_cluster_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for S3 access
resource "aws_iam_policy" "app_s3_policy" {
  name        = "${var.project_name}-${var.environment}-irsa-s3-policy"
  description = "IAM policy for S3 access via IRSA"

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
        Resource = [
          "arn:aws:s3:::${var.public_bucket_name}",
          "arn:aws:s3:::${var.public_bucket_name}/*",
          "arn:aws:s3:::${var.private_bucket_name}",
          "arn:aws:s3:::${var.private_bucket_name}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "app_s3_policy_attachment" {
  role       = aws_iam_role.app_service_account_role.name
  policy_arn = aws_iam_policy.app_s3_policy.arn
}

# Kubernetes Service Account with IRSA annotation
resource "kubernetes_service_account" "app_service_account" {
  metadata {
    name      = "${var.project_name}-service-account"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.app_service_account_role.arn
    }
  }

  depends_on = [aws_iam_role.app_service_account_role]
}
