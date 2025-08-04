# AWS Lambda Billing Function

This project provisions an AWS Lambda function using Python 3.13 that queries and returns the top 5 service charges from your current AWS monthly bill using the Cost Explorer API.

## Features

- **Cost Analysis**: Retrieves the top 5 AWS services by cost for the current month
- **Detailed Reporting**: Shows service names, costs, and percentage of total bill
- **Robust Deployment**: Enhanced bash scripts with comprehensive error handling
- **Secure Permissions**: Custom IAM policy with minimal required permissions for Cost Explorer access
- **Easy Cleanup**: Complete resource cleanup with confirmation prompts

## Requirements

- AWS CLI configured with appropriate credentials
- Python 3.13 Lambda runtime available in your AWS region
- AWS account with Cost Explorer enabled (may require billing data)
- IAM permissions to create roles, policies, and Lambda functions

## Important Notes

- **Cost Explorer Access**: This function requires access to AWS Cost Explorer API, which may have associated costs
- **Billing Data**: The function will only return meaningful data if your AWS account has billing activity
- **Permissions**: The deployment creates a custom IAM policy with Cost Explorer permissions

## Project Structure

```
.
├── README.md                    # This file
├── deploy.sh                   # Robust deployment script
├── cleanup.sh                  # Comprehensive cleanup script
├── trust-policy.json          # IAM role trust policy
├── cost-explorer-policy.json   # Custom IAM policy for Cost Explorer access
└── lambda/
    └── lambda_function.py      # Lambda function code
```

## Usage

### Deploy the Function

Make the deployment script executable and run it:

```bash
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
- Check all prerequisites (AWS CLI, credentials, required files)
- Create the necessary IAM role with appropriate permissions
- Create a custom IAM policy for Cost Explorer access
- Package and deploy the Lambda function
- Test the function and display the results

### Manual Testing

You can manually invoke the function after deployment:

```bash
aws lambda invoke --function-name aws-billing-top5-function --payload '{}' output.json
```

To view the human-readable output, extract the body from the JSON response:

```bash
# Using jq (if available)
jq -r '.body' output.json

# Using Python
python3 -c "import json; print(json.load(open('output.json'))['body'])"

# Or view the raw JSON response
cat output.json
```

### Example Output

The function returns human-readable billing information in the following format:

```
============================================================
AWS BILLING REPORT - August 2025
============================================================
Report Period: 2025-08-01 to 2025-08-04
Total Monthly Cost: $12.17

TOP 5 SERVICES BY COST:
------------------------------------------------------------
1. Amazon Route 53                     $    3.54 ( 29.0%)
2. Amazon Q                            $    1.66 ( 13.6%)
3. Amazon Elastic Load Balancing       $    1.49 ( 12.2%)
4. AWS Security Hub                    $    1.35 ( 11.1%)
5. Amazon Virtual Private Cloud        $    0.97 (  8.0%)
------------------------------------------------------------
Other Services (19): $    3.18 ( 26.1%)
------------------------------------------------------------
Total Services: 24
============================================================
```

The output includes:
- **Report Header**: Current month and date range
- **Total Cost**: Sum of all AWS service charges for the period
- **Top 5 Services**: Ranked by cost with dollar amounts and percentages
- **Other Services Summary**: Aggregated cost and count of remaining services
- **Total Services Count**: Number of AWS services with charges
```

## Cleanup

To remove all resources created by this demo:

1. Make the cleanup script executable:
   ```bash
   chmod +x cleanup.sh
   ```

2. Run the cleanup script:
   ```bash
   ./cleanup.sh
   ```

The cleanup script will:
- Prompt for confirmation before proceeding
- Delete the Lambda function
- Remove the IAM role and detach all policies
- Delete the custom Cost Explorer policy
- Clean up local deployment artifacts

## Security Considerations

- The function uses a custom IAM policy with minimal required permissions for Cost Explorer
- The IAM role follows the principle of least privilege
- All AWS API calls are made using the Lambda execution role's credentials

## Troubleshooting

### Common Issues

1. **No billing data**: If your account has no charges, the function will return an empty list
2. **Cost Explorer not enabled**: Some AWS accounts may need to enable Cost Explorer in the billing console
3. **Permission errors**: Ensure your AWS credentials have sufficient permissions to create IAM roles and policies
4. **Region availability**: Ensure Python 3.13 runtime is available in your selected region

### Logs

Check CloudWatch Logs for detailed function execution logs:
```bash
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/aws-billing-top5-function
```

## Cost Considerations

- **Lambda execution**: Minimal cost for function execution
- **Cost Explorer API**: May incur charges for API calls (check AWS pricing)
- **CloudWatch Logs**: Standard logging charges apply

## Customization

You can modify the Lambda function to:
- Change the number of top services returned
- Filter by specific service categories
- Add different time ranges (last month, year-to-date, etc.)
- Include additional cost metrics (unblended cost, usage quantity, etc.)
