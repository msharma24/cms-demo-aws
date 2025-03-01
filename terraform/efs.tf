module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "1.6.0"

  name = "cms-${var.environment}-wordpress"

  # File system configurations
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

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
      description = "Allow NFS traffic from private subnets"
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    ecs_ingress = {
      description              = "Allow ECS tasks to access EFS"
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = module.wordpress_service.security_group_id
    }
  }

  # Access points
  access_points = {
    wordpress = {
      posix_user = {
        gid = 33 # www-data
        uid = 33 # www-data
      }
      root_directory = {
        path = "/wordpress"
        creation_info = {
          owner_gid   = 33
          owner_uid   = 33
          permissions = "0755"
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
} 

