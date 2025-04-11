#!/bin/bash
set -e

STACK_NAME=demo-ecs-app
REGION=us-west-2
REPO_NAME=demo-nodejs-app
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Deploying VPC..."
aws cloudformation deploy --stack-name ${STACK_NAME}-vpc --template-file cloudformation/vpc.yaml --region $REGION --capabilities CAPABILITY_NAMED_IAM

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=demo-vpc" --region $REGION --query "Vpcs[0].VpcId" --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=demo-public-subnet" --region $REGION --query "Subnets[0].SubnetId" --output text)

echo "Deploying ECR..."
aws cloudformation deploy --stack-name ${STACK_NAME}-ecr --template-file cloudformation/ecr.yaml --region $REGION

echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com

echo "Building Docker image for linux/amd64..."
docker buildx build --platform linux/amd64 -t $REPO_NAME ./app --load

echo "Tagging and pushing Docker image..."
docker tag $REPO_NAME:latest ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

echo "Deploying ECS..."
aws cloudformation deploy \
  --stack-name ${STACK_NAME}-ecs \
  --template-file cloudformation/ecs.yaml \
  --region $REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides VpcId=$VPC_ID SubnetId=$SUBNET_ID

echo "Deployment complete."
