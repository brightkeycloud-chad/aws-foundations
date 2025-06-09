# Lambda Epoch Time Function

This project provisions an AWS Lambda function using Python 3.13 that returns the current epoch time.

## Requirements

- AWS CLI configured with appropriate credentials
- Python 3.13 Lambda runtime available in your AWS region

## Usage

Run the deployment script:

```bash
bash deploy.sh
```

This will:
- Create the necessary IAM role
- Package and deploy the Lambda function
- Invoke the function and print the epoch time

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

This will:
- Delete the Lambda function
- Remove the IAM role and its attached policies
- Clean up local deployment artifacts
