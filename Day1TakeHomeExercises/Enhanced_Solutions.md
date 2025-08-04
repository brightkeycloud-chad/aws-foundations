# AWS Foundations Day 1 - Enhanced Exercise Solutions

## 💰 Exercise 1: Financial Guardian Setup

### Basic Setup:
1. **Navigate to Billing Dashboard** → **Billing Preferences**
2. **Enable PDF invoices delivery by email** and confirm email
3. **Enable AWS Free Tier alerts** and confirm email

### Budget Creation:
1. Go to **Budgets** in Billing Console
2. Click **Create Budget** → **Use a template**
3. Select **Monthly cost budget**
4. Set amount to **$10.00**
5. Add your email under recipients
6. Set alert thresholds at **80%** ($8) and **100%** ($10)
7. Click **Create Budget**

### Challenge Answer:
- Screenshot should show budget with $10 limit and two alert thresholds
- Exceeding Free Tier triggers alerts and potential charges for usage beyond free limits

---

## 🔍 Exercise 2: Infrastructure Discovery Mission

### CloudShell Commands:
```bash
# Get availability zones in current region
aws ec2 describe-availability-zones

# Get all AWS regions
aws ec2 describe-regions

# Get your account ID
aws sts get-caller-identity
```

### Challenge Solution:
```bash
# Create and populate info file
echo "AWS Environment Discovery" > aws-info.txt
echo "=========================" >> aws-info.txt
echo "" >> aws-info.txt
echo "Account ID:" >> aws-info.txt
aws sts get-caller-identity --query Account --output text >> aws-info.txt
echo "" >> aws-info.txt
echo "Current Region AZs:" >> aws-info.txt
aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text >> aws-info.txt

# Download the file using CloudShell's download feature
# Actions menu → Download file → aws-info.txt
```

---

## 📊 Exercise 3: Storage Intelligence Setup

### Setup Steps:
1. Navigate to **S3 Console**
2. Go to **Storage Lens** in left sidebar
3. Click **Dashboards** → **Create dashboard** or enable default
4. Review the default dashboard once enabled

### Key Metrics (3 examples):
- **Total storage usage** across all buckets
- **Cost optimization opportunities** (incomplete multipart uploads, etc.)
- **Data retrieval patterns** and access frequency

### Challenge Answer:
"S3 Storage Lens helps startups optimize storage costs by identifying unused data, incomplete uploads, and inefficient storage classes. This visibility prevents unexpected storage bills and helps implement cost-effective data lifecycle policies as the company grows."

---

## 🎮 Exercise 4: Cost Detective Challenge

### Always Free Services (3 examples):
1. **AWS Lambda** - 1 million requests per month
2. **Amazon DynamoDB** - 25 GB storage + 25 read/write capacity units
3. **Amazon SNS** - 1 million publishes per month

### Current Spend Check:
- Navigate to **Billing Dashboard** → **Bills**
- Current month shows month-to-date charges
- Should be $0.00 if only using Free Tier services

### t3.micro Cost Calculation:
```
t3.micro pricing (varies by region, example for us-east-1):
- On-Demand: ~$0.0104/hour
- 24/7 for 30 days: 24 × 30 × $0.0104 = ~$7.49/month
- Note: First 750 hours/month are FREE under Free Tier!
```

---

## 🏆 BONUS Exercise 5: Mini Architecture Proposal

### Sample Proposal for StartupCorp:

**Cost Monitoring Strategy:**
- Implement $10 monthly budget with 80% alerts to prevent surprise bills
- Enable Free Tier alerts to track usage against limits
- Weekly billing dashboard reviews during initial months

**Always Free Services for Startups:**
- Use Lambda for serverless functions (API backends, data processing)
- DynamoDB for NoSQL database needs (user data, session storage)
- SNS for notifications and messaging between services

**Free Tier Recommendations:**
- Monitor EC2 usage carefully (750 hours = ~1 instance 24/7)
- Use S3 Standard storage efficiently (5GB limit)
- Leverage CloudWatch for basic monitoring within free limits

---

## 📝 Sample Deliverable Structure

```
StartupCorp AWS Setup Report
===========================

1. BILLING SETUP COMPLETE
   - Budget: $10/month with alerts at $8 and $10
   - Free Tier monitoring: Enabled
   - [Screenshot attached]

2. ENVIRONMENT DISCOVERY
   - Account ID: 123456789012
   - Region: us-east-1 (4 availability zones)
   - Total AWS regions available: 33

3. ARCHITECTURE RECOMMENDATIONS
   - Implement proactive cost monitoring
   - Leverage Lambda, DynamoDB, SNS for core services
   - Stay within Free Tier limits for first year

4. SURPRISE LEARNING
   - "I didn't realize AWS had so many always-free services!"
   - "CloudShell is incredibly convenient for quick AWS CLI tasks"
```

---

## 🎯 Why These Enhancements Work Better

1. **Scenario-based learning** - Students think like real cloud administrators
2. **Progressive complexity** - Builds from basic setup to analysis
3. **Hands-on discovery** - Students explore rather than just follow steps
4. **Real-world context** - Each task explains why it matters
5. **Deliverable focus** - Creates something students can reference later
6. **Challenge elements** - Encourages deeper exploration
7. **Time-appropriate** - Still completable in 30 minutes but more engaging
