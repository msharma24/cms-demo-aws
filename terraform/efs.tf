module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.5"

  # File system
  name           = "cms-${var.environment}-efs"
  creation_token = "cms-${var.environment}-token"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false
  policy_statements = [
    {
      sid = "AllowECSAccess"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"] # TODO: Replace with specific ECS task execution role ARN
        }
      ]
      conditions = [
        {
          test     = "Bool"
          variable = "aws:SecureTransport"
          values   = ["true"]
        }
      ]
    }
  ]

  # Mount targets / security group
  mount_targets = {
    "${var.aws_region}a" = {
      subnet_id = module.vpc.private_subnets[0]
    }
    "${var.aws_region}b" = {
      subnet_id = module.vpc.private_subnets[1]
    }
  }

  security_group_description = "EFS security group for CMS"
  security_group_vpc_id      = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.private_subnets_list
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
} 

