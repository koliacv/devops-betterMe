# BetterMe DevOps Test 
cluster_name = "betterme-test-dev-eks-cluster"
project_name = "betterme-test"
environment  = "dev"
region       = "us-west-2"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]

# EKS Configuration
eks_version = "1.28"

node_instance_types   = ["t4g.micro"] # Changed from t3.micro to t4g.micro (ARM64)
node_desired_capacity = 2             # Changed from 1 to 2 for HA
node_max_capacity     = 2
node_min_capacity     = 2            # Changed from 1 to 2 to ensure always 2 nodes
ami_type              = "AL2_ARM_64" # ARM64 architecture for t4g instances

# RDS Configuration
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "betterme"
db_username          = "postgres"
db_engine            = "postgres"
db_engine_version    = "16.3"

# RDS Instance Settings
deletion_protection     = false
backup_retention_period = 1
skip_final_snapshot     = true
