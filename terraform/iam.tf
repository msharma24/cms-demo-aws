# Random ID for unique naming
resource "random_id" "random_id" {
  byte_length = 4
}

# ECS Task Role - for the application running in the container
module "ecs_task_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.30.0"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  role_requires_mfa       = false
  create_role            = true
  create_instance_profile = true

  role_name = "cms-${var.environment}-ecs-task-role-${random_id.random_id.hex}"

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.ecs_task_policy.arn
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

# ECS Task Execution Role - for ECS itself
module "ecs_task_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.30.0"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com"
  ]

  role_requires_mfa       = false
  create_role            = true
  create_instance_profile = true

  role_name = "cms-${var.environment}-ecs-task-execution-role-${random_id.random_id.hex}"

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.ecs_task_execution_policy.arn
  ]

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

# Additional policy for ECS Task Role
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "cms-${var.environment}-ecs-task-policy-${random_id.random_id.hex}"
  description = "Additional permissions for ECS Task Role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = module.efs.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
}

# Additional policy for ECS Task Execution Role
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "cms-${var.environment}-ecs-task-execution-policy-${random_id.random_id.hex}"
  description = "Additional permissions for ECS Task Execution Role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ecs/cms-${var.environment}-*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:cms-${var.environment}-*"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }
} 



#-------------------------------------------------------------------------- 
# IAM assumable role                                                        
#-------------------------------------------------------------------------- 
module "test_instance_iam_assumable_role" {                                 
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"     
  version = "~> 4.5"                                                        
                                                                            
  trusted_role_services = [                                                 
    "ec2.amazonaws.com"                                                     
  ]                                                                         
                                                                            
  role_requires_mfa       = false                                           
  create_role             = true                                            
  create_instance_profile = true                                            
                                                                            
  role_name = "test-instance-role-${random_id.random_id.hex}"               
                                                                            
  custom_role_policy_arns = [                                               
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",             
                                                                            
  ]                                                                         
}                                                                           
