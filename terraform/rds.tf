# Generate random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
  # Avoid password validation issues
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store RDS password in SSM Parameter Store
resource "aws_ssm_parameter" "rds_password" {
  name        = "/cms/${var.environment}/rds/password"
  description = "Master password for RDS Aurora MySQL cluster"
  type        = "SecureString"
  value       = random_password.rds_password.result

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

module "aurora_mysql" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.12.0"

  name              = "cms-${var.environment}-mysql"
  engine            = "aurora-mysql"
  engine_version    = "8.0"
  engine_mode       = "provisioned"
  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 4
  }

  # Instance configuration
  instance_class = "db.serverless"
  instances = {
    1 = {
      identifier = "cms-${var.environment}-mysql"
    }
  }

  # Storage
  storage_encrypted = true
  storage_type      = "aurora"

  # Authentication
  master_username = "wordpress_admin"
  manage_master_user_password = true

  # Network
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = var.private_subnets_list
    }
  }

  # Monitoring and maintenance
  monitoring_interval = 60
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  
  # Backup and maintenance
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:09:00"

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Database parameters
  db_parameter_group_family = "aurora-mysql8.0"
  db_cluster_parameter_group_family = "aurora-mysql8.0"
  
  db_cluster_parameter_group_parameters = [
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    },
    {
      name  = "max_connections"
      value = "{DBInstanceClassMemory/12582880}"
    }
  ]

  apply_immediately   = true
  skip_final_snapshot = false
  final_snapshot_identifier = "cms-${var.environment}-mysql-final-snapshot"

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
} 