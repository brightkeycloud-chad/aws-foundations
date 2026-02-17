#!/usr/bin/env bash
set -euo pipefail

TABLE_NAME="Music"
REGION="us-east-1"

echo "=== Deleting DynamoDB table: $TABLE_NAME ==="
aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION" --output json
echo "Table deletion initiated."
