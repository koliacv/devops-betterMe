# S3 Module - Main Configuration
# Creates public and private S3 buckets for the application

# Random suffix for bucket names to ensure uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Public S3 Bucket
resource "aws_s3_bucket" "public" {
  bucket        = "${var.project_name}-${var.environment}-public-${random_string.bucket_suffix.result}"
  force_destroy = true

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

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

# Public bucket policy to allow public read access
resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.public.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public]
}

# Private S3 Bucket
resource "aws_s3_bucket" "private" {
  bucket        = "${var.project_name}-${var.environment}-private-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-bucket"
    Type = "Private"
  })
}

resource "aws_s3_bucket_ownership_controls" "private" {
  bucket = aws_s3_bucket.private.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "private" {
  depends_on = [aws_s3_bucket_ownership_controls.private]
  bucket     = aws_s3_bucket.private.id
  acl        = "private"
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

resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Test objects
resource "aws_s3_object" "public_test" {
  bucket       = aws_s3_bucket.public.id
  key          = "test.txt"
  content      = "This is a test file in the public bucket."
  content_type = "text/plain"

  tags = var.tags
}

resource "aws_s3_object" "private_test" {
  bucket       = aws_s3_bucket.private.id
  key          = "test.txt"
  content      = "This is a test file in the private bucket."
  content_type = "text/plain"

  tags = var.tags
}
