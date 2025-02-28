module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.4.1"

  # Replication Group settings
  create_cluster           = false
  create_replication_group = true
  replication_group_id     = "cms-${var.environment}-redis"
  description             = "Redis replication group for WordPress CMS"

  engine         = "redis"
  engine_version = "7.1"
  port          = 6379
  node_type     = "cache.t4g.small"

  num_cache_clusters = 2
  automatic_failover_enabled = true
  multi_az_enabled          = true
  apply_immediately         = true
  maintenance_window        = "sun:05:00-sun:09:00"

  # Advanced settings
  auto_minor_version_upgrade = true
  snapshot_retention_limit   = 7
  snapshot_window           = "03:00-04:00"

  # Network settings
  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  # Security group rules
  security_group_rules = {
    ingress_vpc = {
      description = "Redis access from within VPC"
      cidr_ipv4  = module.vpc.vpc_cidr_block
    }
  }

  # Parameter group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "maxmemory-policy"
      value = "allkeys-lru"
    },
    {
      name  = "notify-keyspace-events"
      value = "Ex"
    }
  ]

  # Tags
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
} 