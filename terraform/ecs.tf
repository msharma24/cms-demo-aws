locals {
  container_name = "wordpress"
  container_port = 80
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.12.0"

  cluster_name = "cms-${var.environment}-cluster"

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 0
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

module "wordpress_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.0"

  name                = "wordpress"
  cluster_arn         = module.ecs_cluster.cluster_arn
  desired_count       = 2
  launch_type        = "FARGATE"
  subnet_ids         = module.vpc.private_subnets
  enable_execute_command = true

  runtime_platform = {
    platform_version = "LATEST"
    operating_system = "LINUX"
    cpu_architecture = "X86_64"
  }

  # Container definition(s)
  container_definitions = {
    wordpress = {
      cpu       = 1024
      memory    = 2048
      essential = true
      image     = "wordpress:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort     = local.container_port
          protocol     = "tcp"
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = module.aurora_mysql.cluster_endpoint
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = module.aurora_mysql.cluster_master_username
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = "wordpress"
        },
        {
          name  = "WORDPRESS_REDIS_HOST"
          value = module.redis.replication_group_primary_endpoint_address
        },
        {
          name  = "WORDPRESS_REDIS_PORT"
          value = "6379"  # Default Redis port
        }
      ]

      secrets = [
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = aws_ssm_parameter.rds_password.arn
        }
      ]

      mount_points = [
        {
          sourceVolume  = "wordpress-data"
          containerPath = "/var/www/html"
          readOnly     = false
        }
      ]

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = "/ecs/wordpress-${var.environment}"
          awslogs-stream-prefix = "wordpress"
        }
      }
    }
  }

  volume = {
    wordpress-data = {
      efs_volume_configuration = {
        file_system_id = module.efs.id
        root_directory = "/"
      }
    }
  }

  security_group_rules = {
    alb_ingress = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["wordpress"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

# CloudWatch Log Group for WordPress ecs
module "wordpress_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "4.3.0"

  name              = "/ecs/wordpress-${var.environment}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

# Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.wordpress_service.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.wordpress_log_group.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = module.wordpress_log_group.cloudwatch_log_group_arn
} 