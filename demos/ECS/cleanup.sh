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
# Delete all images in the repository
aws ecr batch-delete-image \
    --repository-name $REPO_NAME \
    --image-ids "$(aws ecr list-images \
    --repository-name $REPO_NAME \
    --query 'imageIds[*]' \
    --output json)" \
    --region $REGION || true

aws cloudformation delete-stack --stack-name ${STACK_NAME}-ecr --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}-ecr --region $REGION

echo "Deleting VPC stack..."
aws cloudformation delete-stack --stack-name ${STACK_NAME}-vpc --region $REGION
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}-vpc --region $REGION

echo "Cleanup complete."