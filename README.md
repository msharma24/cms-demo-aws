# CMS Demo AWS

This repository contains infrastructure code for a CMS demo on AWS using ECS Fargate .

## Infrastructure Components

### ECS (Elastic Container Service)
- **Cluster Configuration**:
  - Mixed capacity providers strategy (60% On-Demand, 40% Spot)
  - Fargate launch type for serverless container management
  - Auto-scaling based on CPU, Memory, and Request Count metrics
  - Target tracking scaling policies with cooldown periods

- **WordPress Service**:
  - Bitnami WordPress container with customized configuration
  - EFS integration for persistent storage
  - ALB integration with health checks
  - Environment variables for WordPress configuration
  - Automated database connection management
  - Custom entrypoint script for initialization and permissions

### RDS (Aurora MySQL)
- **Cluster Configuration**:
  - Aurora MySQL 8.0 with Serverless v2
  - Auto-scaling capacity (0.5 ACU to 4 ACU)
  - Multi-AZ deployment for high availability
  - Automated backups with 7-day retention
  - Performance Insights enabled
  - Enhanced monitoring enabled

### EFS (Elastic File System)
- **Storage Configuration**:
  - General Purpose performance mode
  - Bursting throughput mode
  - Encrypted at rest
  - Lifecycle management (transition to IA after 30 days)
  - Access points for WordPress, Apache, and PHP data
  - Mount targets in private subnets

### Redis (ElastiCache)
- **Cluster Configuration**:
  - Redis 7.1 engine
  - Multi-AZ with automatic failover
  - Node type: cache.t4g.small
  - Two cache clusters for high availability
  - Maintenance window configured
  - Parameter group customization for WordPress caching

## Known Issues and Workarounds

### Bitnami WordPress Container Permissions
**Issue**: The default Bitnami WordPress public ECR image has permission issues with EFS mounts on ECS Fargate.

**Current Workaround**:
- Running container as root (UID 0)
- Setting directory permissions to 777
- Using root group for EFS access points

**Recommended Solution**:
Build a custom Docker image that:
- Properly configures user/group permissions
- Modifies the WordPress application to work with EFS
- Implements proper security practices
- Uses least privilege principle

## Monitoring and Alerts

### CloudWatch Alarms
- **Application Load Balancer**:
  - 5XX error rate monitoring
  - Unhealthy host count tracking
  - Target group health monitoring

- **RDS**:
  - CPU utilization (threshold: 80%)
  - Available memory monitoring
  - Connection count tracking

- **Redis**:
  - CPU utilization (threshold: 80%)
  - Memory usage monitoring
  - Connection tracking

- **EFS**:
  - Burst credit balance monitoring
  - Storage metrics tracking
  - Client connection monitoring

- **ECS**:
  - Service CPU utilization
  - Service memory utilization
  - Task health monitoring

### CIS Alarms
- Implements AWS CIS Benchmark monitoring
- Tracks security-related events
- Monitors AWS account activities
- Alerts on suspicious activities
- Integrated with SNS for notifications

## Manual Configuration Steps

### Domain Configuration (GoDaddy)
1. Log in to your GoDaddy account
2. Navigate to your domain's DNS settings
3. Add the following NS records from AWS Route 53:
   ```
   ns-XXXX.awsdns-XX.com.
   ns-XXXX.awsdns-XX.net.
   ns-XXXX.awsdns-XX.co.uk.
   ns-XXXX.awsdns-XX.org.
   ```
   (Replace XXXX with the actual values from Route 53)

### SSL/TLS Certificate
- ACM certificate is automatically validated using DNS validation
- No manual intervention required
- Certificate renewal is automated

## Infrastructure Deployment

### Prerequisites
- AWS CLI installed and configured
- Terraform v1.0 or later
- Domain registered (GoDaddy or other registrar)
- AWS account with appropriate permissions

### Deployment Steps
1. Set up Terraform backend (follow instructions in Terraform Backend Setup section)
2. Configure environment-specific variables in `env/<environment>/terraform.tfvars`
3. Configure backend settings in `env/<environment>/backend.conf`
4. Use the `run_terraform.sh` script for deployment:

   ```bash
   # Syntax
   ./terraform/run_terraform.sh <environment> <action> [dirty]

   # Examples:
   
   # Plan changes for dev environment
   ./terraform/run_terraform.sh dev

   # Deploy to dev environment
   ./terraform/run_terraform.sh dev deploy

   # Destroy dev environment
   ./terraform/run_terraform.sh dev destroy

   # Plan without cleaning .terraform directory
   ./terraform/run_terraform.sh dev "" dirty
   ```

   **Script Features**:
   - Manages Terraform plugin cache
   - Handles environment-specific configurations
   - Supports multiple environments (dev, staging, prod)
   - Automatic cleanup of .terraform directory
   - Parallel execution for faster deployment
   - Automated plan and apply process
   - Proper exit code handling

   **Parameters**:
   - `<environment>`: Required. Environment name (dev, staging, prod)
   - `<action>`: Optional. Actions: deploy, destroy (default: plan only)
   - `[dirty]`: Optional. Skip .terraform cleanup if specified

   **Environment Structure**:
   ```
   env/
   ├── dev/
   │   ├── terraform.tfvars
   │   └── backend.conf
   ├── staging/
   │   ├── terraform.tfvars
   │   └── backend.conf
   └── prod/
       ├── terraform.tfvars
       └── backend.conf
   ```

## Security Features
- Private subnets for compute resources
- Security groups with least privilege access
- KMS encryption for sensitive data
- SSL/TLS termination at ALB
- WAF integration (optional)
- Network ACLs for additional security
- IAM roles with minimal required permissions

## Cost Optimization
- Mixed usage of Spot and On-Demand instances
- Auto-scaling based on demand
- EFS lifecycle management
- RDS Serverless v2 for dynamic scaling
- Redis cache to reduce database load

## Backup and Recovery
- RDS automated backups
- EFS backup policies
- WordPress content persistence
- Multi-AZ deployments
- Disaster recovery capabilities

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