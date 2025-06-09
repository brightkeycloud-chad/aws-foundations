#!/bin/bash
set -e

# Config
FUNCTION_NAME=printEpochTimeFunction
ROLE_NAME=lambda_basic_execution
ZIP_FILE=lambda_function.zip

# Delete Lambda function
echo "Deleting Lambda function..."
aws lambda delete-function --function-name $FUNCTION_NAME || true

# Detach role policies and delete IAM role
echo "Cleaning up IAM role..."
aws iam detach-role-policy --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole || true
aws iam delete-role --role-name $ROLE_NAME || true

# Clean up local files
rm -f $ZIP_FILE output.json

echo "Cleanup complete."