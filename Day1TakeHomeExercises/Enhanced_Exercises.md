# AWS Foundations Day 1 - Enhanced Take-Home Exercises
*Estimated completion time: 25-30 minutes*

## 🎯 Scenario: You're the new Cloud Administrator for "StartupCorp"
Your manager has asked you to set up proper cost monitoring and explore AWS basics for the company's new AWS account. Complete these tasks as if you're preparing a brief report for your team.

---

## 💰 Exercise 1: Financial Guardian Setup
**Task**: Set up comprehensive billing monitoring for StartupCorp
- Enable PDF email delivery of monthly bills
- Enable AWS Free Tier alerts
- Create a $10 monthly budget with 80% and 100% threshold alerts
- **Challenge**: Take a screenshot of your budget configuration and note what happens if you exceed the Free Tier

**Real-world context**: Companies need proactive cost monitoring to avoid surprise bills.

---

## 🔍 Exercise 2: Infrastructure Discovery Mission
**Task**: Use AWS CloudShell to gather intelligence about your AWS environment
- Open CloudShell and run commands to discover:
  - All availability zones in your current region
  - All AWS regions available to your account
  - Your account ID (hint: use `aws sts get-caller-identity`)
- **Challenge**: Create a simple text file in CloudShell with this information and download it

**Real-world context**: Understanding your AWS environment is crucial for architecture planning.

---

## 📊 Exercise 3: Storage Intelligence Setup
**Task**: Configure S3 Storage Lens for future storage optimization
- Enable the default S3 Storage Lens dashboard
- Navigate through the dashboard and identify 3 key metrics it tracks
- **Challenge**: Explain in 2-3 sentences why this tool would be valuable for a growing startup

**Real-world context**: Storage costs can grow quickly; monitoring helps optimize spending.

---

## 🎮 Exercise 4: Cost Detective Challenge
**Task**: Investigate and document your findings
- Review the AWS Free Tier page and identify 3 services with "Always Free" offerings
- Check your current month's billing dashboard - what's your current spend?
- **Challenge**: Calculate how much it would cost to run a t3.micro EC2 instance 24/7 for a month in your region (don't actually launch it!)

**Real-world context**: Understanding pricing helps make informed architectural decisions.

---

## 🏆 BONUS Exercise 5: Mini Architecture Proposal
**Task**: Based on what you've learned, write a brief proposal (3-4 bullet points) for StartupCorp's initial AWS setup focusing on:
- Cost monitoring strategy
- Which "Always Free" services could benefit a startup
- One recommendation for staying within Free Tier limits

**Challenge**: Present this as if you're briefing your manager - be concise but informative!

---

## 📝 Deliverable
Create a simple document (can be a text file) with:
1. Screenshots of your budget and billing setup
2. Your CloudShell discovery results
3. Your mini architecture proposal
4. One thing that surprised you during these exercises

---

## 💡 Learning Objectives Achieved
- AWS Console navigation
- Cost management fundamentals
- CLI basics with CloudShell
- Understanding AWS Free Tier
- Real-world scenario application
