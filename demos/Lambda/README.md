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
