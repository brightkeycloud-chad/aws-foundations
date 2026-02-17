#!/usr/bin/env bash
set -euo pipefail

TABLE_NAME="Music"
REGION="us-east-1"

echo "=========================================="
echo "  QUERY: All songs by The Beatles"
echo "=========================================="
aws dynamodb query \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --key-condition-expression "Artist = :artist" \
    --expression-attribute-values '{":artist":{"S":"The Beatles"}}' \
    --output table

echo ""
echo "=========================================="
echo "  QUERY: Prince songs starting with 'P'"
echo "=========================================="
aws dynamodb query \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --key-condition-expression "Artist = :artist AND begins_with(SongTitle, :prefix)" \
    --expression-attribute-values '{":artist":{"S":"Prince"},":prefix":{"S":"P"}}' \
    --output table

echo ""
echo "=========================================="
echo "  GET ITEM: Aretha Franklin - Respect"
echo "=========================================="
aws dynamodb get-item \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --key '{"Artist":{"S":"Aretha Franklin"},"SongTitle":{"S":"Respect"}}' \
    --output json

echo ""
echo "=========================================="
echo "  SCAN: All songs from the 1960s"
echo "=========================================="
aws dynamodb scan \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --filter-expression "#yr BETWEEN :start AND :end" \
    --expression-attribute-names '{"#yr":"Year"}' \
    --expression-attribute-values '{":start":{"N":"1960"},":end":{"N":"1969"}}' \
    --output table

echo ""
echo "=========================================="
echo "  SCAN: Full table (all items)"
echo "=========================================="
aws dynamodb scan \
    --table-name "$TABLE_NAME" \
    --region "$REGION" \
    --output table
