# SNS Topic for CloudWatch Alarms
module "cloudwatch_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.1.1"

  name = "${var.environment}-cloudwatch-alarms-sns-topic"
  subscriptions = [
    {
      protocol = "email"
      endpoint = "ms+cloudwatch@mukeshsharma.dev"
    }
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Service     = "monitoring"
  }
}

# ALB Alarms
module "alb_alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-alb-5xx-errors"
  alarm_description   = "ALB 5XX error rate is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10
  period             = 300
  unit               = "Count"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"
  statistic   = "Sum"

  dimensions = {
    LoadBalancer = module.alb.arn_suffix
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

# Redis Alarms
module "redis_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-redis-cpu-utilization"
  alarm_description   = "Redis CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period             = 300
  unit               = "Percent"

  namespace   = "AWS/ElastiCache"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  dimensions = {
    CacheClusterId = module.redis.replication_group_id
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

module "redis_memory_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-redis-memory-utilization"
  alarm_description   = "Redis memory utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period             = 300
  unit               = "Percent"

  namespace   = "AWS/ElastiCache"
  metric_name = "DatabaseMemoryUsagePercentage"
  statistic   = "Average"

  dimensions = {
    CacheClusterId = module.redis.replication_group_id
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

# RDS Alarms
module "rds_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-rds-cpu-utilization"
  alarm_description   = "RDS CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period             = 300
  unit               = "Percent"

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  dimensions = {
    DBClusterIdentifier = module.aurora_mysql.cluster_id
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

module "rds_memory_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-rds-freeable-memory"
  alarm_description   = "RDS freeable memory is low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 1073741824 # 1GB in bytes
  period             = 300
  unit               = "Bytes"

  namespace   = "AWS/RDS"
  metric_name = "FreeableMemory"
  statistic   = "Average"

  dimensions = {
    DBClusterIdentifier = module.aurora_mysql.cluster_id
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

# EFS Alarms
module "efs_burst_credit_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-efs-burst-credits"
  alarm_description   = "EFS burst credits are low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 1000000000000 # 1TB in bytes
  period             = 300
  unit               = "Count"

  namespace   = "AWS/EFS"
  metric_name = "BurstCreditBalance"
  statistic   = "Average"

  dimensions = {
    FileSystemId = module.efs.id
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

# ECS Alarms
module "ecs_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-ecs-cpu-utilization"
  alarm_description   = "ECS service CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period             = 300
  unit               = "Percent"

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  dimensions = {
    ClusterName = module.ecs_cluster.cluster_name
    ServiceName = module.wordpress_service.name
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

module "ecs_memory_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-ecs-memory-utilization"
  alarm_description   = "ECS service memory utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  period             = 300
  unit               = "Percent"

  namespace   = "AWS/ECS"
  metric_name = "MemoryUtilization"
  statistic   = "Average"

  dimensions = {
    ClusterName = module.ecs_cluster.cluster_name
    ServiceName = module.wordpress_service.name
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
}

# Service Health Alarms
module "service_health_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.6.1"

  alarm_name          = "${var.environment}-service-health"
  alarm_description   = "Service health check failures detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1
  period             = 300
  unit               = "Count"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Maximum"

  dimensions = {
    TargetGroup  = try(module.alb.target_groups["wordpress"].arn_suffix, "")
    LoadBalancer = module.alb.arn_suffix
  }

  alarm_actions = [module.cloudwatch_sns_topic.topic_arn]
  ok_actions    = [module.cloudwatch_sns_topic.topic_arn]
} 