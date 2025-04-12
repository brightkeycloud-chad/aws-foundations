#!/bin/bash
set -e

# Config
FUNCTION_NAME=printEpochTimeFunction
ROLE_NAME=lambda_basic_execution
ZIP_FILE=lambda_function.zip
RUNTIME=python3.13
HANDLER=lambda_function.lambda_handler

# Create IAM Role if it doesn't exist
if ! aws iam get-role --role-name $ROLE_NAME >/dev/null 2>&1; then
  aws iam create-role --role-name $ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json
  aws iam attach-role-policy --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  echo "Waiting for role to propagate..."
  sleep 10
fi

# Package Lambda function
cd lambda
zip -r9 ../$ZIP_FILE .
cd ..

# Create Lambda function
if aws lambda get-function --function-name $FUNCTION_NAME >/dev/null 2>&1; then
  aws lambda update-function-code --function-name $FUNCTION_NAME --zip-file fileb://$ZIP_FILE
else
  aws lambda create-function --function-name $FUNCTION_NAME \
    --runtime $RUNTIME \
    --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME \
    --handler $HANDLER \
    --zip-file fileb://$ZIP_FILE
fi

# Invoke Lambda function
aws lambda invoke --function-name $FUNCTION_NAME --payload '{}' output.json
echo "Lambda function output:"
cat output.json
