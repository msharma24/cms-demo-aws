module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.0"

  name = "cms-${var.environment}-wordpress"

  # File system configurations
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # File system policy to allow read/write access
  attach_policy = true
  bypass_policy_lockout_safety_check = false
  policy_statements = [
    {
      sid     = "AllowECSAccess"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ]
      principals = [
        {
          type = "AWS"
          identifiers = ["*"]
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
    for subnet in module.vpc.private_subnets : subnet => {
      subnet_id = subnet
    }
  }

  security_group_description = "EFS security group for WordPress"
  security_group_vpc_id     = module.vpc.vpc_id
  security_group_rules = {
    vpc_ingress = {
      description = "Allow NFS traffic from private subnets (standard port)"
      type        = "ingress"
      from_port   = 2049
      to_port     = 2051  # Include all three ports in range
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    ecs_ingress = {
      description              = "Allow ECS tasks to access EFS on all ports"
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2051  # Include all three ports in range
      protocol                 = "tcp"
      source_security_group_id = module.wordpress_service.security_group_id
    }
  }

  # Access points with proper permissions for Bitnami WordPress
  access_points = {
    wordpress = {
      posix_user = {
        gid = 0  # Root group
        uid = 0  # Root user
      }
      root_directory = {
        path = "/"
        creation_info = {
          owner_gid   = 0  # Root group owns the files
          owner_uid   = 0  # Root user owns the files
          permissions = "0777"  # Full permissions for debugging
        }
      }
    }
    apache = {
      posix_user = {
        gid = 0  # Root group
        uid = 0  # Root user
      }
      root_directory = {
        path = "/apache"
        creation_info = {
          owner_gid   = 0  # Root group owns the files
          owner_uid   = 0  # Root user owns the files
          permissions = "0777"  # Full permissions for debugging
        }
      }
    }
    php = {
      posix_user = {
        gid = 0  # Root group
        uid = 0  # Root user
      }
      root_directory = {
        path = "/php"
        creation_info = {
          owner_gid   = 0  # Root group owns the files
          owner_uid   = 0  # Root user owns the files
          permissions = "0777"  # Full permissions for debugging
        }
      }
    }
  }

  # Lifecycle policy for cost optimization
  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
} 

