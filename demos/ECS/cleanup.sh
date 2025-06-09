#!/bin/bash
set -e

STACK_NAME=demo-ecs-app
REGION=us-west-2
REPO_NAME=demo-nodejs-app
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Deleting ECS stack..."
aws cloudformation delete-stack --stack-name ${STACK_NAME}-ecs --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}-ecs --region $REGION

echo "Deleting ECR stack and repository contents..."
# Check if repository exists before trying to delete images
if aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION 2>/dev/null; then
    # Get image IDs and delete them if any exist
    IMAGE_IDS=$(aws ecr list-images --repository-name $REPO_NAME --region $REGION --query 'imageIds[*]' --output json)
    if [ "$IMAGE_IDS" != "[]" ]; then
        aws ecr batch-delete-image \
            --repository-name $REPO_NAME \
            --image-ids "$IMAGE_IDS" \
            --region $REGION
    fi
fi

# Delete the ECR stack
aws cloudformation delete-stack --stack-name ${STACK_NAME}-ecr --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}-ecr --region $REGION

echo "Deleting VPC stack..."
aws cloudformation delete-stack --stack-name ${STACK_NAME}-vpc --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}-vpc --region $REGION

echo "Cleanup complete."