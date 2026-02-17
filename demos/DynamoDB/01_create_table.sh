#!/usr/bin/env bash
set -euo pipefail

TABLE_NAME="Music"
REGION="us-east-1"

echo "=== Creating DynamoDB table: $TABLE_NAME ==="

aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema \
        AttributeName=Artist,KeyType=HASH \
        AttributeName=SongTitle,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    --output json

echo ""
echo "=== Waiting for table to become ACTIVE ==="
aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"

STATUS=$(aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" --query 'Table.TableStatus' --output text)
echo "Table status: $STATUS"
