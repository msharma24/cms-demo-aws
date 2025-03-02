locals {
  container_name = "wordpress"
  container_port = 8080 # Using non-privileged port
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.12.0"

  cluster_name = "cms-${var.environment}-cluster"

  # Fargate capacity providers with mixed strategy (On-Demand + Spot) as per AWS blog
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 60 # 60% on-demand for stability
        base   = 1  # Ensure at least one task runs on-demand
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 40 # 40% spot for cost optimization
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

  name                   = "wordpress"
  cluster_arn            = module.ecs_cluster.cluster_arn
  desired_count          = 1
  launch_type            = "FARGATE"
  subnet_ids             = module.vpc.private_subnets
  enable_execute_command = true

  # Task role permissions for EFS with comprehensive access
  tasks_iam_role_statements = [
    {
      actions = [
        "elasticfilesystem:*"  # Full EFS permissions
      ]
      resources = ["*"]
      effect    = "Allow"
    },
    {
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["*"]
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
      image     = "public.ecr.aws/bitnami/wordpress:latest"

      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "BITNAMI_DEBUG"
          value = "true"
        },
        {
          name  = "ALLOW_EMPTY_PASSWORD"
          value = "no"
        },
        {
          name  = "WORDPRESS_DATA_TO_PERSIST"
          value = "wp-config.php .htaccess wp-content uploads"
        },
        {
          name  = "WP_DEBUG"
          value = "true"
        },
        {
          name  = "WP_DEBUG_LOG"
          value = "true"
        },
        {
          name  = "WP_DEBUG_DISPLAY"
          value = "false"
        },
        {
          name  = "APACHE_LOG_LEVEL"
          value = "debug"
        },
        {
          name  = "PHP_ERROR_LOG"
          value = "/opt/bitnami/php/logs/error.log"
        },
        {
          name  = "PHP_DISPLAY_ERRORS"
          value = "On"
        },
        {
          name  = "WORDPRESS_SKIP_BOOTSTRAP"
          value = "no"
        },
        {
          name  = "WORDPRESS_ENABLE_HTTPS"
          value = "yes"
        },
        {
          name  = "WORDPRESS_BLOG_NAME"
          value = "WordPress on ECS"
        },
        {
          name  = "WORDPRESS_DATABASE_HOST"
          value = module.aurora_mysql.cluster_endpoint
        },
        {
          name  = "WORDPRESS_DATABASE_PORT_NUMBER"
          value = "3306"
        },
        {
          name  = "WORDPRESS_DATABASE_USER"
          value = module.aurora_mysql.cluster_master_username
        },
        {
          name  = "WORDPRESS_DATABASE_NAME"
          value = "wordpress"
        },
        {
          name  = "WORDPRESS_TABLE_PREFIX"
          value = "wp_"
        },
        {
          name  = "WORDPRESS_ENABLE_XML_RPC"
          value = "no"
        },
        {
          name  = "WORDPRESS_AUTO_UPDATE_LEVEL"
          value = "none"
        },
        {
          name  = "WORDPRESS_EXTRA_WP_CONFIG_CONTENT"
          value = "define('WP_REDIS_HOST', '${module.redis.replication_group_primary_endpoint_address}'); define('WP_REDIS_PORT', 6379); define('WP_CACHE', true);"
        },
        {
          name  = "APACHE_HTTP_PORT_NUMBER"
          value = tostring(local.container_port)
        },
        {
          name  = "PHP_MEMORY_LIMIT"
          value = "512M"
        },
        {
          name  = "PHP_MAX_EXECUTION_TIME"
          value = "300"
        },
        {
          name  = "PHP_MAX_INPUT_VARS"
          value = "2000"
        },
        {
          name  = "PHP_POST_MAX_SIZE"
          value = "128M"
        },
        {
          name  = "PHP_UPLOAD_MAX_FILESIZE"
          value = "128M"
        },
        {
          name  = "PHP_ENABLE_OPCACHE"
          value = "yes"
        },
        {
          name  = "PHP_EXPOSE_PHP"
          value = "no"
        },
        {
          name  = "APACHE_ENABLE_CUSTOM_CONF"
          value = "yes"
        },
        {
          name  = "APACHE_CONF_FILE"
          value = "/opt/bitnami/apache/conf/httpd.conf"
        },
        {
          name  = "APACHE_VHOSTS_DIR"
          value = "/opt/bitnami/apache/conf/bitnami"
        },
        {
          name  = "APACHE_HTTPS_PORT_NUMBER"
          value = "8443"
        },
        {
          name  = "BITNAMI_VOLUME_DIR"
          value = "/bitnami"
        },
        {
          name  = "WORDPRESS_FORCE_INITIALIZATION"
          value = "yes"  # Force initialization to ensure proper setup
        },
        {
          name  = "WORDPRESS_USERNAME"
          value = "admin"  # Default admin username
        },
        {
          name  = "WORDPRESS_ENABLE_HTTPS_REDIRECT"
          value = "no"  # Disable HTTPS redirect to simplify initial setup
        },
        {
          name  = "ALLOW_OVERRIDE_NONE"
          value = "no"  # Allow .htaccess files
        },
        {
          name  = "WORDPRESS_OVERRIDE_DATABASE_SETTINGS"
          value = "yes"  # Force using environment variables for DB settings
        },
        {
          name  = "WORDPRESS_RESET_DATA_PERMISSIONS"
          value = "yes"  # Force reset permissions on persisted data
        },
        {
          name  = "WORDPRESS_EMAIL"
          value = "admin@example.com"  # Email for admin user
        },
        {
          name  = "WORDPRESS_FIRST_NAME"
          value = "WordPress"  # First name for admin user
        },
        {
          name  = "WORDPRESS_LAST_NAME"
          value = "Admin"  # Last name for admin user
        },
        {
          name  = "WORDPRESS_SKIP_BOOTSTRAP"
          value = "no"  # Ensure bootstrap runs if needed
        },
        {
          name  = "WORDPRESS_EXTRA_INSTALL_ARGS"
          value = "--skip-email"  # Skip email notification during initial setup
        }
      ]

      # Run as root for debugging permissions
      user = "0:0"

      secrets = [
        {
          name      = "WORDPRESS_DATABASE_PASSWORD"
          valueFrom = aws_ssm_parameter.rds_password.arn
        },
        {
          name      = "WORDPRESS_PASSWORD"
          valueFrom = aws_ssm_parameter.wordpress_admin_password.arn
        }
      ]

      mount_points = [
        {
          sourceVolume  = "wordpress-data"
          containerPath = "/bitnami/wordpress"
          readOnly      = false
        },
        {
          sourceVolume  = "apache-data"
          containerPath = "/bitnami/apache"
          readOnly      = false
        },
        {
          sourceVolume  = "php-data"
          containerPath = "/bitnami/php"
          readOnly      = false
        }
      ]

      healthcheck = {
        command     = ["CMD-SHELL", "/opt/bitnami/scripts/wordpress/healthcheck.sh"]
        interval    = 60
        timeout     = 30
        retries     = 5
        startPeriod = 300
      }

      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = "/ecs/wordpress-${var.environment}"
          awslogs-stream-prefix = "wordpress"
        }
      }

      # Explicitly disable read-only root filesystem
      readonly_root_filesystem = false
    }
  }

  volume = {
    wordpress-data = {
      name = "wordpress-data"
      efs_volume_configuration = {
        file_system_id          = module.efs.id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2049  # Standard NFS port
        authorization_config = {
          access_point_id = module.efs.access_points["wordpress"].id
          iam             = "ENABLED"
        }
      }
    }
    apache-data = {
      name = "apache-data"
      efs_volume_configuration = {
        file_system_id          = module.efs.id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2050  # Use unique port for Apache
        authorization_config = {
          access_point_id = module.efs.access_points["apache"].id
          iam             = "ENABLED"
        }
      }
    }
    php-data = {
      name = "php-data"
      efs_volume_configuration = {
        file_system_id          = module.efs.id
        root_directory          = "/"
        transit_encryption      = "ENABLED"
        transit_encryption_port = 2051  # Use unique port for PHP
        authorization_config = {
          access_point_id = module.efs.access_points["php"].id
          iam             = "ENABLED"
        }
      }
    }
  }

  # Auto-scaling configuration as per AWS blog
  enable_autoscaling = true
  autoscaling_policies = {
    cpu_tracking = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value       = 75.0
        scale_in_cooldown  = 60
        scale_out_cooldown = 60
      }
    }
  }

  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 4

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

# Add WordPress admin password parameter
resource "aws_ssm_parameter" "wordpress_admin_password" {
  name        = "/cms/${var.environment}/wordpress/admin-password"
  description = "WordPress admin password"
  type        = "SecureString"
  value       = var.wordpress_admin_password
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

