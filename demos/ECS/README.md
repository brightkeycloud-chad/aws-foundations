# ECS Node.js Demo

A simple Node.js application deployed to AWS ECS (Elastic Container Service) using CloudFormation Infrastructure as Code (IaC). This project demonstrates how to set up a containerized Node.js application with a complete AWS infrastructure including VPC, ECR, and ECS Fargate.

## Project Structure

```
.
├── app/                    # Application source code
│   ├── Dockerfile         # Container definition for the Node.js app
│   └── index.js           # Simple Express.js application
├── cloudformation/        # CloudFormation templates
│   ├── ecr.yaml          # ECR repository definition
│   ├── ecs.yaml          # ECS cluster and service definition
│   └── vpc.yaml          # VPC network infrastructure
├── deploy.sh             # Deployment automation script
└── README.md             # Project documentation
```

## Prerequisites

- AWS CLI installed and configured with appropriate credentials
- Docker installed locally
- Node.js (for local development)
- AWS Account with appropriate permissions

## Application Details

The application is a simple Express.js web server that:
- Runs on port 3000
- Serves a basic "Hello" message
- Is containerized using Docker
- Uses Node.js 22 as the base image

## Infrastructure Components

1. **VPC (Virtual Private Cloud)**
   - Custom VPC with public subnets
   - Internet Gateway for public access
   - Appropriate routing and network ACLs

2. **ECR (Elastic Container Registry)**
   - Private container registry
   - Stores the Node.js application Docker image
   - Repository name: demo-nodejs-app

3. **ECS (Elastic Container Service)**
   - Fargate launch type for serverless container management
   - Service and task definitions
   - Application load balancer for traffic distribution

## Deployment Process

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd ecs-nodejs-demo
   ```

2. Make the deployment script executable:
   ```bash
   chmod +x deploy.sh
   ```

3. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

The deployment script will:
1. Deploy the VPC infrastructure
2. Create an ECR repository
3. Build and push the Docker image
4. Deploy the ECS cluster and service

## Configuration

The deployment is configured for the `us-west-2` region by default. To modify the deployment region or other parameters, edit the following variables in `deploy.sh`:

```bash
STACK_NAME=demo-ecs-app
REGION=us-west-2
REPO_NAME=demo-nodejs-app
```

## Local Development

To run the application locally:

1. Navigate to the app directory:
   ```bash
   cd app
   ```

2. Install dependencies:
   ```bash
   npm install express
   ```

3. Run the application:
   ```bash
   node index.js
   ```

4. Access the application at `http://localhost:3000`

## Docker Build

To build the Docker image locally:

```bash
docker build -t demo-nodejs-app ./app
docker run -p 3000:3000 demo-nodejs-app
```

## Security Considerations

- The application runs in a public subnet but can be modified to use private subnets with a NAT Gateway
- ECR repository is private and requires AWS authentication
- ECS tasks use IAM roles for secure AWS service access

## Cost Considerations

This deployment includes several AWS resources that may incur costs:
- ECS Fargate tasks
- Application Load Balancer
- ECR Repository storage
- VPC networking components

## Cleanup

To avoid ongoing charges, delete the CloudFormation stacks, after deleting the one ECR container image first (by hand):

```bash
aws cloudformation delete-stack --stack-name demo-ecs-app-ecs --region us-west-2
aws cloudformation delete-stack --stack-name demo-ecs-app-ecr --region us-west-2
aws cloudformation delete-stack --stack-name demo-ecs-app-vpc --region us-west-2
```
