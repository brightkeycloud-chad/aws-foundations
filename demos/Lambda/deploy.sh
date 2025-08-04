#!/bin/bash

# AWS Lambda Billing Function Deployment Script
# This script deploys a Lambda function that queries the top 5 AWS service charges

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Configuration
readonly FUNCTION_NAME="aws-billing-top5-function"
readonly ROLE_NAME="lambda-billing-execution-role"
readonly POLICY_NAME="lambda-cost-explorer-policy"
readonly ZIP_FILE="lambda_function.zip"
readonly RUNTIME="python3.13"
readonly HANDLER="lambda_function.lambda_handler"
readonly TIMEOUT=30
readonly MEMORY_SIZE=128

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if required files exist
    if [[ ! -f "trust-policy.json" ]]; then
        log_error "trust-policy.json not found in current directory"
        exit 1
    fi
    
    if [[ ! -f "cost-explorer-policy.json" ]]; then
        log_error "cost-explorer-policy.json not found in current directory"
        exit 1
    fi
    
    if [[ ! -d "lambda" ]] || [[ ! -f "lambda/lambda_function.py" ]]; then
        log_error "Lambda function code not found in lambda/ directory"
        exit 1
    fi
    
    # Check if zip command is available
    if ! command -v zip &> /dev/null; then
        log_error "zip command is not available. Please install it first."
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Get AWS account ID
get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

# Create or update IAM role
setup_iam_role() {
    local account_id
    account_id=$(get_account_id)
    
    log_info "Setting up IAM role: $ROLE_NAME"
    
    # Create IAM role if it doesn't exist
    if ! aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        log_info "Creating IAM role..."
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document file://trust-policy.json \
            --description "Lambda execution role for AWS billing function"
        
        # Attach basic Lambda execution policy
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        
        log_info "Role created successfully"
    else
        log_info "IAM role already exists"
    fi
    
    # Create custom policy for Cost Explorer access
    local policy_arn="arn:aws:iam::${account_id}:policy/${POLICY_NAME}"
    
    if ! aws iam get-policy --policy-arn "$policy_arn" &> /dev/null; then
        log_info "Creating Cost Explorer policy..."
        aws iam create-policy \
            --policy-name "$POLICY_NAME" \
            --policy-document file://cost-explorer-policy.json \
            --description "Policy for Lambda function to access Cost Explorer API"
        log_info "Policy created successfully"
    else
        log_info "Cost Explorer policy already exists"
    fi
    
    # Attach Cost Explorer policy to role
    if ! aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query "AttachedPolicies[?PolicyArn=='$policy_arn']" --output text | grep -q "$policy_arn"; then
        log_info "Attaching Cost Explorer policy to role..."
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "$policy_arn"
        log_info "Policy attached successfully"
    else
        log_info "Cost Explorer policy already attached to role"
    fi
    
    # Wait for role propagation
    log_info "Waiting for IAM role propagation..."
    sleep 30
}

# Package Lambda function
package_function() {
    log_info "Packaging Lambda function..."
    
    # Clean up any existing zip file
    rm -f "$ZIP_FILE"
    
    # Create zip package
    cd lambda
    if ! zip -r9 "../$ZIP_FILE" . &> /dev/null; then
        log_error "Failed to create zip package"
        exit 1
    fi
    cd ..
    
    # Verify zip file was created
    if [[ ! -f "$ZIP_FILE" ]]; then
        log_error "Zip file was not created"
        exit 1
    fi
    
    local zip_size
    zip_size=$(stat -f%z "$ZIP_FILE" 2>/dev/null || stat -c%s "$ZIP_FILE" 2>/dev/null)
    log_info "Package created successfully (${zip_size} bytes)"
}

# Deploy Lambda function
deploy_function() {
    local account_id
    account_id=$(get_account_id)
    local role_arn="arn:aws:iam::${account_id}:role/${ROLE_NAME}"
    
    log_info "Deploying Lambda function: $FUNCTION_NAME"
    
    if aws lambda get-function --function-name "$FUNCTION_NAME" &> /dev/null; then
        log_info "Updating existing function..."
        aws lambda update-function-code \
            --function-name "$FUNCTION_NAME" \
            --zip-file "fileb://$ZIP_FILE"
        
        # Update function configuration
        aws lambda update-function-configuration \
            --function-name "$FUNCTION_NAME" \
            --runtime "$RUNTIME" \
            --handler "$HANDLER" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY_SIZE"
        
        log_info "Function updated successfully"
    else
        log_info "Creating new function..."
        aws lambda create-function \
            --function-name "$FUNCTION_NAME" \
            --runtime "$RUNTIME" \
            --role "$role_arn" \
            --handler "$HANDLER" \
            --zip-file "fileb://$ZIP_FILE" \
            --timeout "$TIMEOUT" \
            --memory-size "$MEMORY_SIZE" \
            --description "Lambda function to get top 5 AWS service charges from current monthly bill"
        
        log_info "Function created successfully"
    fi
    
    # Wait for function to be ready
    log_info "Waiting for function to be ready..."
    aws lambda wait function-active --function-name "$FUNCTION_NAME"
}

# Test Lambda function
test_function() {
    log_info "Testing Lambda function..."
    
    local output_file="output.json"
    
    if aws lambda invoke \
        --function-name "$FUNCTION_NAME" \
        --payload '{}' \
        "$output_file" &> /dev/null; then
        
        log_info "Function invoked successfully"
        echo
        echo "=== Lambda Function Output ==="
        if [[ -f "$output_file" ]]; then
            # Extract and display the body content in a readable format
            if command -v jq &> /dev/null; then
                # Use jq if available for better JSON parsing
                jq -r '.body' "$output_file" 2>/dev/null || cat "$output_file"
            else
                # Fallback: try to extract body using basic tools
                if grep -q '"body"' "$output_file"; then
                    # Extract the body content and unescape it
                    python3 -c "
import json
import sys
try:
    with open('$output_file', 'r') as f:
        data = json.load(f)
    if 'body' in data:
        print(data['body'])
    else:
        print(json.dumps(data, indent=2))
except:
    with open('$output_file', 'r') as f:
        print(f.read())
" 2>/dev/null || cat "$output_file"
                else
                    cat "$output_file"
                fi
            fi
            echo
        fi
        echo "=============================="
        echo
    else
        log_error "Failed to invoke Lambda function"
        exit 1
    fi
}

# Cleanup function for error handling
cleanup_on_error() {
    log_warn "Cleaning up due to error..."
    rm -f "$ZIP_FILE" output.json
}

# Main execution
main() {
    log_info "Starting AWS Lambda billing function deployment..."
    
    # Set up error handling
    trap cleanup_on_error ERR
    
    check_prerequisites
    setup_iam_role
    package_function
    deploy_function
    test_function
    
    # Clean up temporary files
    rm -f "$ZIP_FILE"
    
    log_info "Deployment completed successfully!"
    echo
    echo "Function Name: $FUNCTION_NAME"
    echo "Role Name: $ROLE_NAME"
    echo "Policy Name: $POLICY_NAME"
    echo
    echo "To invoke the function manually:"
    echo "aws lambda invoke --function-name $FUNCTION_NAME --payload '{}' output.json"
}

# Run main function
main "$@"
