# S3 Module - Main Configuration
# Creates public and private S3 buckets with appropriate access policies

# Local variables for naming and tagging consistency
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standard tags with module information
  common_tags = merge(var.tags, {
    Module = "s3"
  })
}

# Random suffix for unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Public S3 Bucket
resource "aws_s3_bucket" "public" {
  bucket = "${var.project_name}-${var.environment}-public-${random_string.bucket_suffix.result}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-bucket"
    Type = "Public"
  })
}

resource "aws_s3_bucket_versioning" "public" {
  bucket = aws_s3_bucket.public.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public bucket access configuration
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.public.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.public.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public]
}

# Private S3 Bucket
resource "aws_s3_bucket" "private" {
  bucket = "${var.project_name}-${var.environment}-private-${random_string.bucket_suffix.result}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-bucket"
    Type = "Private"
  })
}

resource "aws_s3_bucket_versioning" "private" {
  bucket = aws_s3_bucket.private.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Private bucket access configuration (block all public access)
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# VPC Endpoint policy for private S3 access
resource "aws_s3_bucket_policy" "private" {
  bucket = aws_s3_bucket.private.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "VPCEndpointAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.private.arn,
          "${aws_s3_bucket.private.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:sourceVpc" = var.vpc_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.private]
}

// TODO: just for testing purposes, will remove this for production
resource "aws_s3_object" "public_test" {
  bucket       = aws_s3_bucket.public.id
  key          = "test.txt"
  content      = "Hello from public S3 bucket! This file is accessible from anywhere."
  content_type = "text/plain"

  tags = var.tags
}
// TODO: just for testing purposes, will remove this for production
resource "aws_s3_object" "private_test" {
  bucket       = aws_s3_bucket.private.id
  key          = "test.txt"
  content      = "Hello from private S3 bucket! This file is only accessible from VPC."
  content_type = "text/plain"

  tags = var.tags
}
