# Product Service - Cloud Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?style=flat-square&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=flat-square&logo=amazon-aws)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=flat-square&logo=postgresql)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python)

**Enterprise-grade cloud infrastructure with auto-scaling, serverless email verification, automated DNS management, and comprehensive security**

---

## 📋 Table of Contents 

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [DNS Management](#-dns-management)
- [Configuration](#-configuration)
- [Testing](#-testing)
- [Security Mechanism](#-security-mechanism)
- [Project Structure](#-project-structure)

---

## 🎯 Overview

Production-ready AWS infrastructure for a RESTful product management service.

### Features

- **High Availability**: Multi-AZ deployment with 3-5 auto-scaling instances
- **Automated DNS**: Terraform-managed Route53 with Root and Dev Hosted Zones
- **Serverless Email**: SNS + Lambda for user verification workflow
- **Security**: KMS encryption, Secrets Manager, private network isolation
- **Zero Downtime**: Rolling updates with health check validation
- **Full Automation**: Infrastructure as Code with CI/CD pipeline

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Infrastructure** | Terraform (modular, 9 modules) |
| **Compute** | EC2 Auto Scaling, Application Load Balancer |
| **Database** | RDS PostgreSQL 16.3 (encrypted, Multi-AZ ready) |
| **Storage** | S3 (KMS encrypted, lifecycle policies) |
| **Serverless** | Lambda (Python 3.11), SNS |
| **Security** | KMS (4 keys), Secrets Manager, Security Groups |
| **DNS** | Route53 (Root + Dev Hosted Zones) |

**Total**: ~70 AWS resources, ~3,300 lines of Terraform code

---

## 🏗️ Architecture

### High-Level Diagram
```
                          Internet
                             ↓
                    ┌────────────────┐
                    │   Namecheap    │ (One-time NS setup)
                    └────────┬───────┘
                             │
                    ┌────────▼────────┐
                    │ Root Zone (TF)  │ chs4150.me
                    │  NS Delegation  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Dev Zone (TF)   │ dev.chs4150.me
                    │  A Record       │
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │ Application Load Balancer   │
              └──────────────┬──────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
   │ EC2 (1a)│          │ EC2 (1b)│          │ EC2 (1c)│
   └────┬────┘          └────┬────┘          └────┬────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────┴─────────┐
                    ↓                  ↓
            RDS PostgreSQL         S3 Bucket
            (Private Subnet)       (Images)

Email Flow: EC2 → SNS → Lambda → Mailgun → User
```

### Modules
```
networking  → VPC, 6 subnets (3 AZs), 3 security groups
security    → 4 KMS keys, 3 secrets (DB, Mailgun)
database    → RDS PostgreSQL 16.3, encrypted, backups
storage     → S3 bucket, KMS encryption, lifecycle
serverless  → SNS topic, Lambda (email handler)
compute     → ASG (3-5 instances), ALB, scaling policies
dns/root    → Route53 Root Hosted Zone, NS delegation
dns/dev     → Route53 Dev Hosted Zone, A record to ALB
```

---

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.5.0, AWS CLI >= 2.0
- AWS accounts with `dev` and `root` profiles configured
- Domain registered (e.g., chs4150.me via Namecheap)
- Mailgun account (API key required)
- EC2 key pair created

### Deploy
```bash
# 1. Configure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set: domain_name, mailgun_api_key, key_name

# 2. Create Lambda placeholder
mkdir -p /tmp/lambda && cd /tmp/lambda
echo 'def lambda_handler(e,c): return {"statusCode":200}' > email_handler.py
zip lambda_placeholder.zip email_handler.py
cp lambda_placeholder.zip <tf-aws-infra-path>/

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply  # ~10-15 minutes

# 4. View deployment instructions
terraform output post_deployment_instructions
```

### Post-Deployment
```bash
# 1. Get Root Zone Name Servers
terraform output root_name_servers

# 2. Update Namecheap Custom DNS

# 3. Wait for DNS propagation (15-30 minutes)

# 4. Verify deployment
./scripts/check-nameservers.sh
curl http://dev.chs4150.me/health
```

---

## 🌐 DNS Management

### Automated DNS Architecture

**Terraform manages both Root and Dev Hosted Zones with automatic NS delegation:**

```
┌─────────────────────────────────────────┐
│ Namecheap (Manual, One-time)            │
│ ├─ Custom DNS → Root Zone NS           │
│ └─ Update only when Root NS changes     │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ Root Hosted Zone (Terraform)            │
│ ├─ Domain: chs4150.me                   │
│ ├─ NS: Auto-generated by AWS            │
│ └─ NS Delegation: dev.chs4150.me        │
│    └─ Auto-synced with Dev Zone NS ✅   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ Dev Hosted Zone (Terraform)             │
│ ├─ Domain: dev.chs4150.me               │
│ ├─ NS: Auto-generated by AWS            │
│ └─ A Record: Alias to ALB               │
│    └─ Auto-tracked by Terraform ✅      │
└─────────────────────────────────────────┘
```

### DNS Automation Benefits

| Feature | Status | Description |
|---------|--------|-------------|
| **Root Zone** | ✅ Automated | Created/destroyed with `terraform apply/destroy` |
| **Dev Zone** | ✅ Automated | Managed by Terraform |
| **NS Delegation** | ✅ Automated | Root automatically syncs with Dev Zone NS |
| **A Record** | ✅ Automated | Automatically tracks ALB DNS changes |
| **Namecheap NS** | ⚠️ Manual | One-time update when Root NS changes |

**Check with:**
```bash
./scripts/check-nameservers.sh
```

---

## ⚙️ Configuration

### Required Variables
```hcl
# terraform.tfvars
domain_name     = "dev.chs4150.me"  # Your dev subdomain
mailgun_api_key = "your-api-key"    # From Mailgun dashboard
key_name        = "your-keypair"    # EC2 key pair name
```

### Optional Tuning
```hcl
# Auto Scaling
asg_min_size = 3  # Min instances
asg_max_size = 5  # Max instances

# Database
db_instance_class = "db.t3.micro"
db_allocated_storage = 20  # GB

# Compute
instance_type = "t2.micro"
```

### AWS CLI Profiles

**Required profiles in `~/.aws/config`:**

```ini
[profile dev]
region = us-east-1

[profile root]
region = us-east-1
```

**Note**: Root profile can point to the same account for simplified setup.

---

## 🧪 Testing

### Auto Scaling Test

<div align="center">
<img src="docs/images/auto-scaling-demo.png" alt="Auto Scaling Test" width="500"/>
</div>

**Results:**
- ✅ Baseline: 3 instances
- ✅ Load applied (CPU 22-26%) → Scaled to 5 instances in ~2 min
- ✅ Load removed (CPU 4-11%) → Scaled to 3 instances in ~3 min
- ✅ Zero downtime during scaling

**Run test:**
```bash
bash scripts/test_autoscaling.sh
```

### DNS Verification
```bash
# Check Name Server synchronization
./scripts/check-nameservers.sh

# Expected output (when synced):
# ✅ Name Servers are up to date!
# ✅ dev.chs4150.me resolves to: 52.x.x.x
# ✅ API is responding (HTTP 200)
# 🎉 Everything is working!
```

### Email Verification
```bash
# Register user (triggers email)
curl -X POST http://dev.chs4150.me/v1/user \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Pass123!","firstName":"John","lastName":"Doe"}'

# Check Lambda logs
aws logs tail /aws/lambda/product-service-dev-email-handler --follow

# Verify account (click link in email within 1 minute)
```

---

## 🔒 Security Mechanism

### Encryption

| Resource | Method | Key |
|----------|--------|-----|
| RDS Database | AES-256 | KMS (auto-rotate) |
| S3 Bucket | SSE-KMS | KMS (auto-rotate) |
| EBS Volumes | AES-256 | KMS (auto-rotate) |
| Secrets | AES-256 | KMS (auto-rotate) |

### Network Isolation

- RDS in private subnets (no internet)
- S3 public access blocked
- EC2 only accessible via ALB
- Security groups: least-privilege rules

### Secrets Management

Stored in AWS Secrets Manager (KMS encrypted):
- `product-service/dev/rds/password` (auto-generated)
- `product-service/dev/email/mailgun-api-key`
- `product-service/dev/email/mailgun-domain`

### Implementation Notes

- 🔐 **Use personal credentials**
  - Update with your AWS credentials, Mailgun API key, domain name

- 🔄 **Rotate all secrets for production**
  - Database passwords
  - API keys
  - Use AWS Secrets Manager rotation features

- 🚧 **Production security hardening**
  - Restrict SSH access to specific IP ranges (currently open to 0.0.0.0/0)
  - Enable AWS WAF on Application Load Balancer
  - Enable MFA for AWS accounts
  - Review and minimize IAM permissions
  - Enable CloudTrail for audit logging

---

## 📂 Project Structure
```
tf-aws-infra/
├── main.tf                      # Module orchestration
├── provider.tf                  # AWS providers (dev + root)
├── variables.tf                 # Global variables
├── outputs.tf                   # Exported values
├── modules/                     # 9 infrastructure modules
│   ├── networking/              # VPC, subnets, security groups
│   ├── security/                # KMS, Secrets Manager
│   ├── database/                # RDS PostgreSQL
│   ├── storage/                 # S3 bucket
│   ├── serverless/
│   │   ├── sns/                 # SNS topic
│   │   └── lambda/              # Lambda function
│   ├── compute/                 # EC2, ALB, Auto Scaling
│   └── dns/
│       ├── root/                # Root Hosted Zone (chs4150.me)
│       └── dev/                 # Dev Hosted Zone (dev.chs4150.me)
└── scripts/
    ├── check-nameservers.sh     # DNS verification script
    ├── test_autoscaling.sh      # Auto-scaling test
    └── user-data.sh             # EC2 initialization
```

**Stats**: 52 files, ~3,300 lines, ~70 AWS resources

---

## 🔧 Maintenance

### Update Infrastructure
```bash
terraform plan    # Preview changes
terraform apply   # Apply changes
```

### Update Application

**Automated**: Push to GitHub → CI/CD builds AMI → Instance refresh → Zero downtime

### Destroy Infrastructure
```bash
# Remove all AWS resources (including Hosted Zones)
terraform destroy

# Cost after destroy: $0
# Note: Will need to update Namecheap NS on next deployment if Root NS changes
```

### Redeploy After Destroy
```bash
# 1. Deploy all resources
terraform apply

# 2. Check if Root NS changed
./scripts/check-nameservers.sh

# 3. If NS changed, update Namecheap (script will show instructions)

# 4. Wait 15-30 minutes for DNS propagation

# 5. Verify
curl http://dev.chs4150.me/health
```

### Backups

- RDS: Daily automated backups (7-day retention)
- Backup window: 03:00-04:00 UTC
- Restore: `aws rds restore-db-instance-from-db-snapshot`

---

## 🐛 Troubleshooting

### DNS Issues

**Domain not resolving?**
```bash
# Check Name Server synchronization
./scripts/check-nameservers.sh

# Manually check DNS propagation
dig dev.chs4150.me +short

# Check Root Zone delegation
dig @ns-105.awsdns-13.com dev.chs4150.me NS +short
```

### Infrastructure Issues

**EC2 Unhealthy?** 
```bash
# Check user data logs
ssh ec2-user@<instance-ip>
sudo cat /var/log/user-data.log
sudo journalctl -u product-service.service
```

**Lambda Not Triggered?** 
```bash
# Verify SNS subscription
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)
```

**RDS Connection Failed?** 
```bash
# Check database password
aws secretsmanager get-secret-value \
  --secret-id product-service/dev/rds/password \
  --query SecretString \
  --output text
```

---

## 🎓 Skills Demonstrated

### Infrastructure & DevOps
- ✅ Multi-account AWS architecture design
- ✅ Automated DNS management with Route53
- ✅ Infrastructure as Code with modular Terraform
- ✅ High availability patterns (Multi-AZ, Auto-scaling)
- ✅ CI/CD pipeline for infrastructure validation

### Security & Compliance
- ✅ Multi-layer encryption (KMS for RDS, S3, EBS, Secrets)
- ✅ Network isolation (VPC, private subnets, security groups)
- ✅ Secrets management with AWS Secrets Manager
- ✅ IAM least-privilege policies
- ✅ No hardcoded credentials

### Cloud-Native Design
- ✅ Stateless application architecture
- ✅ Serverless email workflow (SNS + Lambda)
- ✅ Auto-scaling based on CloudWatch metrics
- ✅ Zero-downtime deployment with instance refresh
- ✅ Infrastructure observability ready (CloudWatch)

---

**Built with Terraform · Deployed on AWS · Monitored with CloudWatch**
