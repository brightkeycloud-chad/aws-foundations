#!/bin/bash

# AWS Lambda Billing Function Cleanup Script
# This script removes all resources created by the deployment

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Configuration
readonly FUNCTION_NAME="aws-billing-top5-function"
readonly ROLE_NAME="lambda-billing-execution-role"
readonly POLICY_NAME="lambda-cost-explorer-policy"
readonly ZIP_FILE="lambda_function.zip"

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

# Check if AWS CLI is available and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured"
        exit 1
    fi
}

# Get AWS account ID
get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

# Delete Lambda function
delete_lambda_function() {
    log_info "Checking for Lambda function: $FUNCTION_NAME"
    
    if aws lambda get-function --function-name "$FUNCTION_NAME" &> /dev/null; then
        log_info "Deleting Lambda function..."
        if aws lambda delete-function --function-name "$FUNCTION_NAME"; then
            log_info "Lambda function deleted successfully"
        else
            log_error "Failed to delete Lambda function"
            return 1
        fi
    else
        log_info "Lambda function does not exist, skipping"
    fi
}

# Detach policies and delete IAM role
cleanup_iam_resources() {
    local account_id
    account_id=$(get_account_id)
    local policy_arn="arn:aws:iam::${account_id}:policy/${POLICY_NAME}"
    
    log_info "Cleaning up IAM resources..."
    
    # Check if role exists
    if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
        log_info "Found IAM role: $ROLE_NAME"
        
        # Detach AWS managed policy
        log_info "Detaching AWS Lambda basic execution policy..."
        if aws iam detach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" 2>/dev/null; then
            log_info "AWS managed policy detached"
        else
            log_warn "AWS managed policy was not attached or failed to detach"
        fi
        
        # Detach custom policy if it exists and is attached
        if aws iam get-policy --policy-arn "$policy_arn" &> /dev/null; then
            log_info "Detaching custom Cost Explorer policy..."
            if aws iam detach-role-policy \
                --role-name "$ROLE_NAME" \
                --policy-arn "$policy_arn" 2>/dev/null; then
                log_info "Custom policy detached"
            else
                log_warn "Custom policy was not attached or failed to detach"
            fi
        fi
        
        # Delete the role
        log_info "Deleting IAM role..."
        if aws iam delete-role --role-name "$ROLE_NAME"; then
            log_info "IAM role deleted successfully"
        else
            log_error "Failed to delete IAM role"
            return 1
        fi
    else
        log_info "IAM role does not exist, skipping"
    fi
    
    # Delete custom policy if it exists
    if aws iam get-policy --policy-arn "$policy_arn" &> /dev/null; then
        log_info "Deleting custom Cost Explorer policy..."
        if aws iam delete-policy --policy-arn "$policy_arn"; then
            log_info "Custom policy deleted successfully"
        else
            log_error "Failed to delete custom policy"
            return 1
        fi
    else
        log_info "Custom policy does not exist, skipping"
    fi
}

# Clean up local files
cleanup_local_files() {
    log_info "Cleaning up local files..."
    
    local files_to_remove=("$ZIP_FILE" "output.json")
    local removed_count=0
    
    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_info "Removed: $file"
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        log_info "No local files to clean up"
    else
        log_info "Cleaned up $removed_count local file(s)"
    fi
}

# Confirmation prompt
confirm_cleanup() {
    echo
    log_warn "This will delete the following resources:"
    echo "  - Lambda function: $FUNCTION_NAME"
    echo "  - IAM role: $ROLE_NAME"
    echo "  - IAM policy: $POLICY_NAME"
    echo "  - Local files: $ZIP_FILE, output.json"
    echo
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
}

# Main cleanup function
main() {
    log_info "Starting AWS Lambda billing function cleanup..."
    
    check_aws_cli
    confirm_cleanup
    
    local cleanup_errors=0
    
    # Delete Lambda function
    if ! delete_lambda_function; then
        ((cleanup_errors++))
    fi
    
    # Clean up IAM resources
    if ! cleanup_iam_resources; then
        ((cleanup_errors++))
    fi
    
    # Clean up local files
    cleanup_local_files
    
    echo
    if [[ $cleanup_errors -eq 0 ]]; then
        log_info "Cleanup completed successfully!"
    else
        log_warn "Cleanup completed with $cleanup_errors error(s)"
        log_warn "Some resources may need to be cleaned up manually"
        exit 1
    fi
    
    echo
    echo "All resources have been removed:"
    echo "✓ Lambda function deleted"
    echo "✓ IAM role and policies removed"
    echo "✓ Local files cleaned up"
}

# Run main function
main "$@"