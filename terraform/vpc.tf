module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "cms-${var.environment}-vpc"
  cidr = var.vpc_cidr_range

  azs              = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets  = var.private_subnets_list
  public_subnets   = var.public_subnets_list
  database_subnets = var.database_subnets_list

  enable_nat_gateway = true
  single_nat_gateway = true # Cost optimization 

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_max_aggregation_interval    = 60


  # Tags for all resources
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
  }

  # Subnet specific tags
  public_subnet_tags = {
    Type = "Public"
  }

  private_subnet_tags = {
    Type = "Private"
  }

  database_subnet_tags = {
    Type = "Database"
  }
}

