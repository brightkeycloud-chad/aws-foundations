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
- AWS Graviton (arm64) Fargate pricing — ~20% cheaper than x86
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
| ECS Fargate (ARM/Graviton) | Vcpu | vCPU-hour | $0.03238 | No free tier for ECS Fargate |
| ECS Fargate (ARM/Graviton) | Memory | GB-hour | $0.00356 | No free tier for ECS Fargate |
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
| ECS Fargate (ARM/Graviton) | Single task running 24/7 with 0.25 vCPU and 0.5 GB memory (Vcpu Hours: 730 hours × 0.25 vCPU = 182.5 vCPU-hours, Memory Hours: 730 hours × 0.5 GB = 365 GB-hours) | $0.03238 × 182.5 vCPU-hours + $0.00356 × 365 GB-hours = $5.91 + $1.30 = $7.21 | $7.21 |
| Amazon ECR | Storage for ~200 MB container image (Storage: 0.2 GB stored for 1 month) | $0.10 × 0.2 GB = $0.02 (covered by free tier) | $0.02 |
| CloudWatch Logs | ~10 MB of logs per day with 7-day retention (Monthly Logs: 10 MB/day × 30 days = 300 MB = 0.3 GB) | $0.50 × 0.3 GB = $0.15 (covered by free tier) | $0.15 |
| VPC Components | VPC, subnet, internet gateway, route table, security group (Components: 1 VPC, 1 subnet, 1 IGW, 1 route table, 1 security group) | All VPC components are free of charge | $0.00 |
| Data Transfer Out | ~4 MB per day (1000 requests × 4 KB each) (Monthly Transfer: 4 MB/day × 30 days = 120 MB = 0.12 GB) | 0.12 GB is within the 1 GB free tier = $0.00 | $0.00 |
| **Total** | **All services** | **Sum of all calculations** | **$7.38/month** |

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
| ECS Fargate (ARM) | $3/month | $7/month | $14/month |
| Amazon ECR | $0/month | $0/month | $0/month |
| CloudWatch Logs | $0/month | $0/month | $0/month |
| VPC Components | Varies | Varies | Varies |
| Data Transfer Out | Varies | Varies | Varies |

### Key Cost Factors

- **ECS Fargate (ARM/Graviton)**: Single task running 24/7 with 0.25 vCPU and 0.5 GB memory
- **Amazon ECR**: Storage for ~200 MB container image
- **CloudWatch Logs**: ~10 MB of logs per day with 7-day retention
- **VPC Components**: VPC, subnet, internet gateway, route table, security group
- **Data Transfer Out**: ~4 MB per day (1000 requests × 4 KB each)

## Projected Costs Over Time

The following projections show estimated monthly costs over a 12-month period based on different growth patterns:

Base monthly cost calculation:

| Service | Monthly Cost |
|---------|-------------|
| ECS Fargate (ARM/Graviton) | $7.21 |
| Amazon ECR | $0.02 |
| CloudWatch Logs | $0.15 |
| **Total Monthly Cost** | **$7** |

| Growth Pattern | Month 1 | Month 3 | Month 6 | Month 12 |
|---------------|---------|---------|---------|----------|
| Steady | $7/mo | $7/mo | $7/mo | $7/mo |
| Moderate | $7/mo | $7/mo | $9/mo | $12/mo |
| Rapid | $7/mo | $8/mo | $11/mo | $20/mo |

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
- ARM/Graviton Fargate is already in use for ~20% cost savings vs x86
- Implement log filtering to reduce CloudWatch Logs ingestion if logs become verbose
- Set up CloudWatch billing alerts to monitor actual costs vs estimates



## Cost Optimization Recommendations

### Immediate Actions

- Monitor actual resource usage after deployment to validate cost estimates
- ARM/Graviton Fargate is already in use for ~20% cost savings vs x86
- Implement log filtering to reduce CloudWatch Logs ingestion if logs become verbose

### Best Practices

- Regularly review costs with AWS Cost Explorer
- Consider reserved capacity for predictable workloads
- Implement automated scaling based on demand

## Conclusion

By following the recommendations in this report, you can optimize your ECS Demo Infrastructure costs while maintaining performance and reliability. Regular monitoring and adjustment of your usage patterns will help ensure cost efficiency as your workload evolves.
