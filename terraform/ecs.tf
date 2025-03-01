locals {
  container_name = "wordpress"
  container_port = 8080
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

  # Task role permissions for EFS
  tasks_iam_role_statements = [
    {
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:DescribeMountTargets",
        "elasticfilesystem:DescribeFileSystems"
      ]
      resources = [module.efs.arn]
      effect    = "Allow"
    },
    {
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = [aws_secretsmanager_secret.dockerhub_credentials.arn]
      effect    = "Allow"
    }
  ]

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
      user      = "33:33"  # Run as www-data user
      
      repository_credentials = {
        credentialsParameter = aws_secretsmanager_secret.dockerhub_credentials.arn
      }

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
        },
        {
          name  = "APACHE_RUN_USER"
          value = "www-data"
        },
        {
          name  = "APACHE_RUN_GROUP"
          value = "www-data"
        },
        {
          name  = "APACHE_RUN_DIR"
          value = "/var/run/apache2"
        },
        {
          name  = "APACHE_PID_FILE"
          value = "/var/run/apache2/apache2.pid"
        },
        {
          name  = "APACHE_LOG_DIR"
          value = "/var/log/apache2"
        },
        {
          name  = "WORDPRESS_CONFIG_EXTRA"
          value = "define('FS_METHOD', 'direct'); define('WP_TEMP_DIR', '/var/www/html/tmp'); define('WP_DEBUG', true);"
        }
      ]

      entrypoint = [
        "sh",
        "-c",
        "mkdir -p /var/www/html/tmp /var/run/apache2 /var/log/apache2 && chmod 775 /var/www/html/tmp /var/run/apache2 /var/log/apache2 && chown www-data:www-data /var/www/html/tmp /var/run/apache2 /var/log/apache2 && sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf && sed -i 's/:80/:8080/g' /etc/apache2/sites-enabled/000-default.conf && docker-entrypoint.sh apache2-foreground"
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
      name = "wordpress-data"
      efs_volume_configuration = {
        file_system_id          = module.efs.id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049
        authorization_config = {
          access_point_id = module.efs.access_points["wordpress"].id
          iam            = "ENABLED"
        }
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

# Docker Hub credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "dockerhub_credentials" {
  name = "cms-${var.environment}-dockerhub-credentials"
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

resource "aws_secretsmanager_secret_version" "dockerhub_credentials" {
  secret_id = aws_secretsmanager_secret.dockerhub_credentials.id
  secret_string = jsonencode({
    username = var.dockerhub_username
    password = var.dockerhub_password
  })
}

variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
}

variable "dockerhub_password" {
  description = "Docker Hub password or access token"
  type        = string
  sensitive   = true
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