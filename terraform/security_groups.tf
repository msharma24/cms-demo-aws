module "efs_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/nfs"
  version = "5.3.0"

  name        = "cms-${var.environment}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = module.vpc.vpc_id

  # Allow NFS traffic only from within the VPC
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
  }
}

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "5.3.0"

  name        = "cms-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTPS from anywhere
  ingress_cidr_blocks = ["0.0.0.0/0"]

  # Add HTTP ingress rule
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
  }
}

module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/postgresql"
  version = "5.3.0"

  name        = "cms-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = module.vpc.vpc_id

  # Allow PostgreSQL access only from private subnets
  ingress_cidr_blocks = var.private_subnets_list

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
  }
}

module "redis_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/redis"
  version = "5.3.0"

  name        = "cms-${var.environment}-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = module.vpc.vpc_id

  # Allow Redis access only from private subnets
  ingress_cidr_blocks = var.private_subnets_list

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
  }
}

module "ecs_wordpress_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "cms-${var.environment}-ecs-wordpress-sg"
  description = "Security group for WordPress ECS Fargate service"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules - allow traffic from ALB
  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                = "tcp"
      description             = "HTTP from ALB"
      source_security_group_id = module.alb_security_group.security_group_id
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                = "tcp"
      description             = "HTTPS from ALB"
      source_security_group_id = module.alb_security_group.security_group_id
    }
  ]

  # Egress rules - allow all outbound traffic
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}
