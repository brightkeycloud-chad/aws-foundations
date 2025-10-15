# ECS Demo Infrastructure Cost Analysis Estimate Report

## Service Overview

ECS Demo Infrastructure is a fully managed, serverless service that allows you to This project uses multiple AWS services.. This service follows a pay-as-you-go pricing model, making it cost-effective for various workloads.

## Pricing Model

This cost analysis estimate is based on the following pricing model:
- **ON DEMAND** pricing (pay-as-you-go) unless otherwise specified
- Standard service configurations without reserved capacity or savings plans
- No caching or optimization techniques applied

## Assumptions

- Single ECS Fargate task running 24/7 (730 hours/month)
- Task configuration: 0.25 vCPU (256 CPU units), 0.5 GB memory (512 MB)
- Container image size: ~200 MB (typical Node.js app)
- Log generation: ~10 MB per day (minimal application logs)
- 1000 requests per day generating ~4 KB response each
- Data transfer out: ~4 MB per day (1000 requests × 4 KB)
- 7-day log retention as configured in CloudFormation
- Standard x86 Fargate pricing (not ARM or Windows)
- No reserved capacity or savings plans applied

## Limitations and Exclusions

- Application Load Balancer costs (not used in this demo)
- NAT Gateway costs (using public subnet with direct internet access)
- S3 costs for storing deployment artifacts
- CloudFormation stack operation costs (minimal)
- Data transfer costs between AZs (single AZ deployment)
- Development and maintenance costs
- Domain name and SSL certificate costs

## Cost Breakdown

### Unit Pricing Details

| Service | Resource Type | Unit | Price | Free Tier |
|---------|--------------|------|-------|------------|
| ECS Fargate | Vcpu | vCPU-hour | $0.04048 | No free tier for ECS Fargate |
| ECS Fargate | Memory | GB-hour | $0.004445 | No free tier for ECS Fargate |
| Amazon ECR | Storage | GB-month | $0.10 | 500 MB free storage per month for 12 months |
| CloudWatch Logs | Ingestion | GB for custom logs (first 10TB) | $0.50 | 5 GB ingestion and 5 GB storage free per month |
| CloudWatch Logs | Storage | 1 unit | Included in ingestion cost for short retention | 5 GB ingestion and 5 GB storage free per month |
| VPC Components | Vpc | 1 unit | $0.00 | VPC components are free |
| VPC Components | Subnet | 1 unit | $0.00 | VPC components are free |
| VPC Components | Internet Gateway | 1 unit | $0.00 | VPC components are free |
| VPC Components | Route Table | 1 unit | $0.00 | VPC components are free |
| VPC Components | Security Group | 1 unit | $0.00 | VPC components are free |
| Data Transfer Out | First 1Gb | GB | $0.00 | 1 GB free data transfer out per month |
| Data Transfer Out | Next 9999Gb | GB | $0.09 | 1 GB free data transfer out per month |

### Cost Calculation

| Service | Usage | Calculation | Monthly Cost |
|---------|-------|-------------|-------------|
| ECS Fargate | Single task running 24/7 with 0.25 vCPU and 0.5 GB memory (Vcpu Hours: 730 hours × 0.25 vCPU = 182.5 vCPU-hours, Memory Hours: 730 hours × 0.5 GB = 365 GB-hours) | $0.04048 × 182.5 vCPU-hours + $0.004445 × 365 GB-hours = $7.39 + $1.62 = $9.01 | $8.86 |
| Amazon ECR | Storage for ~200 MB container image (Storage: 0.2 GB stored for 1 month) | $0.10 × 0.2 GB = $0.02 (covered by free tier) | $0.02 |
| CloudWatch Logs | ~10 MB of logs per day with 7-day retention (Monthly Logs: 10 MB/day × 30 days = 300 MB = 0.3 GB) | $0.50 × 0.3 GB = $0.15 (covered by free tier) | $0.15 |
| VPC Components | VPC, subnet, internet gateway, route table, security group (Components: 1 VPC, 1 subnet, 1 IGW, 1 route table, 1 security group) | All VPC components are free of charge | $0.00 |
| Data Transfer Out | ~4 MB per day (1000 requests × 4 KB each) (Monthly Transfer: 4 MB/day × 30 days = 120 MB = 0.12 GB) | 0.12 GB is within the 1 GB free tier = $0.00 | $0.00 |
| **Total** | **All services** | **Sum of all calculations** | **$9.03/month** |

### Free Tier

Free tier information by service:
- **ECS Fargate**: No free tier for ECS Fargate
- **Amazon ECR**: 500 MB free storage per month for 12 months
- **CloudWatch Logs**: 5 GB ingestion and 5 GB storage free per month
- **VPC Components**: VPC components are free
- **Data Transfer Out**: 1 GB free data transfer out per month

## Cost Scaling with Usage

The following table illustrates how cost estimates scale with different usage levels:

| Service | Low Usage | Medium Usage | High Usage |
|---------|-----------|--------------|------------|
| ECS Fargate | $4/month | $8/month | $17/month |
| Amazon ECR | $0/month | $0/month | $0/month |
| CloudWatch Logs | $0/month | $0/month | $0/month |
| VPC Components | Varies | Varies | Varies |
| Data Transfer Out | Varies | Varies | Varies |

### Key Cost Factors

- **ECS Fargate**: Single task running 24/7 with 0.25 vCPU and 0.5 GB memory
- **Amazon ECR**: Storage for ~200 MB container image
- **CloudWatch Logs**: ~10 MB of logs per day with 7-day retention
- **VPC Components**: VPC, subnet, internet gateway, route table, security group
- **Data Transfer Out**: ~4 MB per day (1000 requests × 4 KB each)

## Projected Costs Over Time

The following projections show estimated monthly costs over a 12-month period based on different growth patterns:

Base monthly cost calculation:

| Service | Monthly Cost |
|---------|-------------|
| ECS Fargate | $8.86 |
| Amazon ECR | $0.02 |
| CloudWatch Logs | $0.15 |
| **Total Monthly Cost** | **$9** |

| Growth Pattern | Month 1 | Month 3 | Month 6 | Month 12 |
|---------------|---------|---------|---------|----------|
| Steady | $9/mo | $9/mo | $9/mo | $9/mo |
| Moderate | $9/mo | $9/mo | $11/mo | $15/mo |
| Rapid | $9/mo | $10/mo | $14/mo | $25/mo |

* Steady: No monthly growth (1.0x)
* Moderate: 5% monthly growth (1.05x)
* Rapid: 10% monthly growth (1.1x)

## Detailed Cost Analysis

### Pricing Model

ON DEMAND


### Exclusions

- Application Load Balancer costs (not used in this demo)
- NAT Gateway costs (using public subnet with direct internet access)
- S3 costs for storing deployment artifacts
- CloudFormation stack operation costs (minimal)
- Data transfer costs between AZs (single AZ deployment)
- Development and maintenance costs
- Domain name and SSL certificate costs

### Recommendations

#### Immediate Actions

- Monitor actual resource usage after deployment to validate cost estimates
- Consider using ARM-based Fargate tasks for ~20% cost savings if application supports it
- Implement log filtering to reduce CloudWatch Logs ingestion if logs become verbose
- Set up CloudWatch billing alerts to monitor actual costs vs estimates



## Cost Optimization Recommendations

### Immediate Actions

- Monitor actual resource usage after deployment to validate cost estimates
- Consider using ARM-based Fargate tasks for ~20% cost savings if application supports it
- Implement log filtering to reduce CloudWatch Logs ingestion if logs become verbose

### Best Practices

- Regularly review costs with AWS Cost Explorer
- Consider reserved capacity for predictable workloads
- Implement automated scaling based on demand

## Conclusion

By following the recommendations in this report, you can optimize your ECS Demo Infrastructure costs while maintaining performance and reliability. Regular monitoring and adjustment of your usage patterns will help ensure cost efficiency as your workload evolves.
