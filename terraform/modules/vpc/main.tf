# VPC Module - Main Configuration

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Prod env setup should contain NAT Gateway with private subnets -- not applied for test task
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Local variables for naming and tagging consistency
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Standard tags with module information
  common_tags = merge(var.tags, {
    Module = "vpc"
  })

  # EKS cluster name for Kubernetes tags
  cluster_name = "${local.name_prefix}-eks-cluster"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name                                          = "${local.name_prefix}-vpc"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  })
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Create Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                                                       = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type                                                                       = "Public"
    "kubernetes.io/role/elb"                                                   = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks-cluster" = "shared"
  })
}

# Create Private Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name                                                                       = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type                                                                       = "Private"
    "kubernetes.io/role/internal-elb"                                          = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-eks-cluster" = "owned"
  })
}

# Create Database Subnets
resource "aws_subnet" "database" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 30)
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-database-${count.index + 1}"
    Type = "Database"
  })
}

# Create Database Subnet Group
resource "aws_db_subnet_group" "database" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "Public"
  })
}

# Create Route Table for Database Subnets
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-database-rt"
    Type = "Database"
  })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate Database Subnets with Database Route Table
resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# Create VPC Endpoint for S3 (for private S3 access)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,  # EKS nodes route table
    aws_route_table.database.id # Database route table
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  })
}

# Data source for current region
data "aws_region" "current" {}
