# CMS Demo AWS

This repository contains infrastructure code for a CMS demo on AWS.

## Terraform Backend Setup

Before deploying the infrastructure, you need to set up the Terraform backend (S3 bucket and DynamoDB table) using the provided CloudFormation template.

### Deploy Terraform Backend

The `terraform-backend-config/deploy-terraform-backend.sh` script creates:
- An S3 bucket for storing Terraform state files
- A DynamoDB table for state locking
- Both resources are configured with security best practices

#### Prerequisites
- AWS CLI installed and configured
- Appropriate AWS permissions to create S3 buckets and DynamoDB tables
- Bash shell environment

#### Usage

1. Deploy with default region (us-east-1):
```bash
./terraform-backend-config/deploy-terraform-backend.sh
```

2. Deploy to a specific region using environment variable:
```bash
AWS_REGION=us-west-2 ./terraform-backend-config/deploy-terraform-backend.sh
```

3. Deploy using AWS CLI configured region:
```bash
aws configure set region eu-west-1
./terraform-backend-config/deploy-terraform-backend.sh
```

#### Features
- Automatic region detection with fallback to us-east-1
- Template validation before deployment
- Stack creation/update detection
- Colored output for better readability
- Stack output display after successful deployment
- Error handling and deployment status checking

#### Resources Created
- S3 Bucket: `terraform-state-backend-${AWS::AccountId}`
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked
  - Retention policy enabled
- DynamoDB Table: `terraform-state-backend-lock-${AWS::AccountId}`
  - On-demand capacity
  - State locking capability
  - Basic encryption enabled

#### Security Features
- S3 bucket:
  - Private access only
  - Encryption at rest
  - Versioning enabled
  - Public access blocked
- DynamoDB:
  - On-demand capacity to prevent throttling
  - Basic encryption enabled
  - Minimal IAM permissions