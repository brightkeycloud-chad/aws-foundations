#!/bin/bash
set -e

# Configuration
STACK_NAME=demo-ecs-app
REGION=us-west-2
REPO_NAME=demo-nodejs-app

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for fun
ROCKET="🚀"
CHECKMARK="✅"
BUILDING="🏗️"
DOCKER="🐳"
CLOUD="☁️"
SPARKLES="✨"

# Helper functions
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

print_info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

# Welcome message
print_header "$ROCKET ECS Fargate Demo Deployment $ROCKET"
echo -e "This script will deploy your awesome Node.js app to AWS ECS Fargate!"
echo -e "Sit back and watch the magic happen... $SPARKLES\n"

# Get AWS account ID
print_step "$BUILDING" "Getting AWS account information..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_success "$CHECKMARK" "Connected to AWS Account: $AWS_ACCOUNT_ID"

# Deploy VPC
print_step "$CLOUD" "Deploying VPC infrastructure..."
aws cloudformation deploy \
    --stack-name ${STACK_NAME}-vpc \
    --template-file cloudformation/vpc.yaml \
    --region $REGION \
    --capabilities CAPABILITY_NAMED_IAM
print_success "$CHECKMARK" "VPC deployed successfully!"

# Get VPC and Subnet IDs
print_step "$BUILDING" "Retrieving network configuration..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=demo-vpc" --region $REGION --query "Vpcs[0].VpcId" --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=demo-public-subnet" --region $REGION --query "Subnets[0].SubnetId" --output text)
print_info "VPC ID: $VPC_ID"
print_info "Subnet ID: $SUBNET_ID"

# Deploy ECR
print_step "$DOCKER" "Setting up container registry..."
aws cloudformation deploy \
    --stack-name ${STACK_NAME}-ecr \
    --template-file cloudformation/ecr.yaml \
    --region $REGION
print_success "$CHECKMARK" "ECR repository created!"

# Docker operations
print_step "$DOCKER" "Authenticating Docker with ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com
print_success "$CHECKMARK" "Docker authenticated!"

print_step "$BUILDING" "Building Docker image (this might take a moment)..."
docker buildx build --platform linux/amd64 -t $REPO_NAME ./app --load
print_success "$CHECKMARK" "Docker image built successfully!"

print_step "$ROCKET" "Pushing image to ECR..."
docker tag $REPO_NAME:latest ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
print_success "$CHECKMARK" "Image pushed to ECR!"

# Deploy ECS
print_step "$CLOUD" "Deploying ECS cluster and service..."
aws cloudformation deploy \
  --stack-name ${STACK_NAME}-ecs \
  --template-file cloudformation/ecs.yaml \
  --region $REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VpcId=$VPC_ID SubnetId=$SUBNET_ID
print_success "$CHECKMARK" "ECS service deployed!"

# Get application URL
print_step "$SPARKLES" "Getting your application details..."
sleep 10  # Give ECS a moment to start the task

TASK_ARN=$(aws ecs list-tasks --cluster demo-cluster --region $REGION --query "taskArns[0]" --output text)
if [ "$TASK_ARN" != "None" ] && [ "$TASK_ARN" != "" ]; then
    PUBLIC_IP=$(aws ecs describe-tasks --cluster demo-cluster --tasks $TASK_ARN --region $REGION --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text | xargs -I {} aws ec2 describe-network-interfaces --network-interface-ids {} --region $REGION --query "NetworkInterfaces[0].Association.PublicIp" --output text)
    
    if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "" ]; then
        print_header "$SPARKLES DEPLOYMENT COMPLETE! $SPARKLES"
        echo -e "${GREEN}Your awesome Node.js app is now running on ECS Fargate!${NC}\n"
        echo -e "${YELLOW}🌐 Application URL: ${NC}${CYAN}http://$PUBLIC_IP:3000${NC}"
        echo -e "${YELLOW}🏥 Health Check:   ${NC}${CYAN}http://$PUBLIC_IP:3000/health${NC}"
        echo -e "${YELLOW}ℹ️  System Info:    ${NC}${CYAN}http://$PUBLIC_IP:3000/info${NC}"
        echo -e "${YELLOW}🎲 Random Facts:   ${NC}${CYAN}http://$PUBLIC_IP:3000/api/random${NC}\n"
        echo -e "${PURPLE}Note: It may take a few minutes for the application to be fully accessible.${NC}"
    else
        print_info "Task is starting up. Use the following command to get the public IP once it's ready:"
        echo -e "${CYAN}aws ecs describe-tasks --cluster demo-cluster --tasks $TASK_ARN --region $REGION${NC}"
    fi
else
    print_info "ECS task is still starting. Check the ECS console for status updates."
fi

print_header "$CHECKMARK All Done! $CHECKMARK"
echo -e "Your containerized Node.js application is now running in the cloud!"
echo -e "Check the AWS ECS console to monitor your service: https://console.aws.amazon.com/ecs/\n"
