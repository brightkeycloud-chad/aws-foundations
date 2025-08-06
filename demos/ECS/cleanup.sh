#!/bin/bash
set -e

# Configuration
STACK_NAME=demo-ecs-app
REGION=us-west-2
REPO_NAME=demo-nodejs-app

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Emojis
CLEANUP="🧹"
WARNING="⚠️"
CHECKMARK="✅"
TRASH="🗑️"

print_header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}\n"
}

print_step() {
    echo -e "${BLUE}$1${NC} $2"
}

print_success() {
    echo -e "${GREEN}$1${NC} $2"
}

print_warning() {
    echo -e "${YELLOW}$1${NC} $2"
}

print_error() {
    echo -e "${RED}$1${NC} $2"
}

# Welcome message
print_header "$CLEANUP ECS Demo Cleanup $CLEANUP"
echo -e "This script will remove all AWS resources created by the ECS demo."
print_warning "$WARNING" "This action cannot be undone!"
echo ""

# Confirmation prompt
read -p "Are you sure you want to delete all demo resources? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "\n${BLUE}Cleanup cancelled. Your resources are safe! 😊${NC}"
    exit 0
fi

echo ""
print_step "$TRASH" "Starting cleanup process..."

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

# Function to safely delete stack
delete_stack() {
    local stack_name=$1
    local description=$2
    
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$REGION" >/dev/null 2>&1; then
        print_step "$TRASH" "Deleting $description..."
        aws cloudformation delete-stack --stack-name "$stack_name" --region "$REGION"
        
        print_step "⏳" "Waiting for $description deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region "$REGION" 2>/dev/null || {
            print_warning "$WARNING" "$description deletion may have failed or is taking longer than expected"
        }
        print_success "$CHECKMARK" "$description deleted successfully!"
    else
        print_warning "$WARNING" "$description stack not found (may already be deleted)"
    fi
}

# Delete ECS stack first (has dependencies)
delete_stack "${STACK_NAME}-ecs" "ECS cluster and service"

# Clean up ECR images before deleting the repository
if [ -n "$AWS_ACCOUNT_ID" ]; then
    print_step "$TRASH" "Cleaning up ECR images..."
    
    # Check if repository exists and has images
    if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
        # Delete all images in the repository
        IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO_NAME" --region "$REGION" --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")
        
        if [ "$IMAGE_IDS" != "[]" ] && [ -n "$IMAGE_IDS" ]; then
            aws ecr batch-delete-image --repository-name "$REPO_NAME" --region "$REGION" --image-ids "$IMAGE_IDS" >/dev/null 2>&1 || true
            print_success "$CHECKMARK" "ECR images cleaned up!"
        else
            print_warning "$WARNING" "No images found in ECR repository"
        fi
    else
        print_warning "$WARNING" "ECR repository not found (may already be deleted)"
    fi
fi

# Delete ECR stack
delete_stack "${STACK_NAME}-ecr" "ECR repository"

# Delete VPC stack last (other resources depend on it)
delete_stack "${STACK_NAME}-vpc" "VPC and networking resources"

# Clean up local Docker images
print_step "$CLEANUP" "Cleaning up local Docker images..."
if docker images -q "$REPO_NAME" >/dev/null 2>&1; then
    docker rmi "$REPO_NAME" >/dev/null 2>&1 || true
    print_success "$CHECKMARK" "Local Docker images cleaned up!"
else
    print_warning "$WARNING" "No local Docker images found to clean up"
fi

# Final success message
print_header "$CHECKMARK Cleanup Complete! $CHECKMARK"
echo -e "${GREEN}All demo resources have been successfully removed from your AWS account.${NC}"
echo -e "${BLUE}💰 You should no longer be charged for these resources.${NC}"
echo -e "${PURPLE}Thanks for trying out the ECS Fargate demo! 🚀${NC}\n"
