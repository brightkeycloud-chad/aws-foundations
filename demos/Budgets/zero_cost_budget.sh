#!/bin/bash

# Variables
BUDGET_NAME="ZeroCostBudget"
EMAIL="chad@brightkeycloud.com"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Generate start date in ISO 8601 format
if date --version >/dev/null 2>&1; then
  START_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # GNU date
else
  START_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # BSD date (macOS)
fi

# Create temp JSON files
BUDGET_JSON=$(mktemp)
NOTIFICATION_JSON=$(mktemp)

# Write budget JSON
cat > "$BUDGET_JSON" <<EOF
{
  "BudgetName": "$BUDGET_NAME",
  "BudgetLimit": {
    "Amount": "0.01",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST",
  "TimePeriod": {
    "Start": "$START_DATE"
  },
  "CostTypes": {
    "IncludeTax": true,
    "IncludeSubscription": true,
    "UseBlended": false,
    "IncludeRefund": true,
    "IncludeCredit": false,
    "IncludeUpfront": true,
    "IncludeRecurring": true,
    "IncludeOtherSubscription": true,
    "IncludeSupport": true,
    "IncludeDiscount": true,
    "UseAmortized": false
  }
}
EOF

# Create budget
aws budgets create-budget \
  --account-id "$ACCOUNT_ID" \
  --budget file://"$BUDGET_JSON" \
  --region $REGION

# Write notification JSON
cat > "$NOTIFICATION_JSON" <<EOF
{
  "Notification": {
    "NotificationType": "ACTUAL",
    "ComparisonOperator": "GREATER_THAN",
    "Threshold": 0,
    "ThresholdType": "ABSOLUTE_VALUE"
  },
  "Subscribers": [
    {
      "SubscriptionType": "EMAIL",
      "Address": "$EMAIL"
    }
  ]
}
EOF

# Create notification
aws budgets create-notification \
  --account-id "$ACCOUNT_ID" \
  --budget-name "$BUDGET_NAME" \
  --notification file://"$NOTIFICATION_JSON" \
  --region $REGION

# Cleanup
rm "$BUDGET_JSON" "$NOTIFICATION_JSON"

echo "✅ Budget '$BUDGET_NAME' created with alert to $EMAIL"
