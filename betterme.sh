#!/bin/bash
set -euo pipefail

# BetterMe DevOps - Simplified Deployment Script
# Usage: ./betterme.sh deploy|destroy

# Configuration
PROJECT_NAME="${PROJECT_NAME:-betterme-test}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_REGION="${AWS_REGION:-us-west-2}"
CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-eks-cluster"

print_usage() {
    echo "Usage: $0 [deploy|destroy]"
    echo "  deploy   - Deploy infrastructure and application"
    echo "  destroy  - Destroy all resources"
}

check_requirements() {
    echo "Checking requirements..."
    command -v terraform >/dev/null 2>&1 || { echo "Error: terraform not found"; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl not found"; exit 1; }
    command -v helm >/dev/null 2>&1 || { echo "Error: helm not found"; exit 1; }
    command -v aws >/dev/null 2>&1 || { echo "Error: aws cli not found"; exit 1; }
    aws sts get-caller-identity >/dev/null || { echo "Error: AWS credentials not configured"; exit 1; }
    echo "Requirements check passed"
}

deploy() {
    echo "Starting deployment..."
    
    # Infrastructure deployment
    echo "Deploying infrastructure..."
    cd terraform
    terraform init -input=false
    terraform plan -var-file="environments/dev/terraform.tfvars" -input=false
    terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve -input=false
    
    # Get outputs
    CLUSTER_NAME_OUTPUT=$(terraform output -raw cluster_name)
    AWS_REGION_OUTPUT=$(terraform output -raw region || echo "$AWS_REGION")
    
    cd ..
    
    # Configure kubectl
    echo "Configuring kubectl..."
    aws eks update-kubeconfig --region "$AWS_REGION_OUTPUT" --name "$CLUSTER_NAME_OUTPUT"
    
    # Wait for nodes
    echo "Waiting for nodes..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Application deployment
    echo "Deploying application..."
    cd k8s
    
    helm upgrade --install betterme-app . \
      --namespace betterme-test \
      --create-namespace \
      --wait \
      --timeout=10m
    
    cd ..
    
    echo "Deployment completed successfully!"
}

destroy() {
    echo "Starting cleanup..."
    
    read -p "Destroy all resources? (yes/no): " confirmation
    if [[ $confirmation != "yes" ]]; then
        echo "Cleanup cancelled"
        exit 1
    fi
    
    # Remove application
    echo "Removing application..."
    cd k8s
    if helm list -n betterme-test | grep -q betterme-app; then
        helm uninstall betterme-app -n betterme-test --wait
    fi
    kubectl delete namespace betterme-test --ignore-not-found=true --wait=true
    cd ..
    
    # Destroy infrastructure
    echo "Destroying infrastructure..."
    cd terraform
    terraform destroy -var-file="environments/dev/terraform.tfvars" -auto-approve -input=false
    cd ..
    
    echo "Cleanup completed successfully!"
}

# Main execution
case "${1:-}" in
    deploy)
        check_requirements
        deploy
        ;;
    destroy)
        check_requirements
        destroy
        ;;
    *)
        print_usage
        exit 1
        ;;
esac 