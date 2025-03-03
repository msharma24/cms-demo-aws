#!/bin/bash

# Set strict error handling
set -euo pipefail
echo "Deploying Terraform state backend..."

# Variables
STACK_NAME="terraform-state-backend"
TEMPLATE_FILE="terraform-backend-cfn.yml"
# Allow region override via environment variable, default to us-east-1
REGION=${AWS_REGION:-$(aws configure get region)}
REGION=${REGION:-"ap-southeast-2"}
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo $REGION
echo $ACCOUNT_ID


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if stack exists
check_stack_exists() {
    aws cloudformation describe-stacks \
        --region $REGION \
        --stack-name $STACK_NAME >/dev/null 2>&1
    return $?
}

# Function to validate template
validate_template() {
    echo -e "${YELLOW}Validating CloudFormation template...${NC}"
    aws cloudformation validate-template \
        --region $REGION \
        --template-body file://$TEMPLATE_FILE
}

# Function to deploy stack
deploy_stack() {
    local operation=$1
    local cmd="aws cloudformation $operation-stack \
        --region $REGION \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --capabilities CAPABILITY_IAM \
        --tags Key=Environment,Value=Production"

    echo -e "${YELLOW}Deploying CloudFormation stack...${NC}"
    $cmd

    echo -e "${YELLOW}Waiting for stack operation to complete...${NC}"
    aws cloudformation wait stack-$operation-complete \
        --region $REGION \
        --stack-name $STACK_NAME

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Stack $operation completed successfully!${NC}"
        
        # Get stack outputs
        echo -e "${YELLOW}Stack Outputs:${NC}"
        aws cloudformation describe-stacks \
            --region $REGION \
            --stack-name $STACK_NAME \
            --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
            --output table
    else
        echo -e "${RED}Stack $operation failed!${NC}"
        exit 1
    fi
}

main() {
    echo -e "${YELLOW}Starting deployment in region: $REGION${NC}"
    echo -e "${YELLOW}Account ID: $ACCOUNT_ID${NC}"

    # Validate template first
    validate_template

    # Check if stack exists and deploy accordingly
    if check_stack_exists; then
        echo -e "${YELLOW}Stack exists, updating...${NC}"
        deploy_stack "update"
    else
        echo -e "${YELLOW}Stack does not exist, creating...${NC}"
        deploy_stack "create"
    fi
}

# Execute main function
echo "Executing main function..."
main 
