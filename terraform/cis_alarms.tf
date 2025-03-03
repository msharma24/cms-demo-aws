#-----------------------------------
# CIS Alarms
#-----------------------------------
module "cis_all_action_types" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/cis-alarms"
  version = "5.6.1"

  log_group_name            = module.cis_log_group.cloudwatch_log_group_name
  alarm_actions             = [module.aws_sns_topic.topic_arn]
  ok_actions                = [module.aws_sns_topic.topic_arn]
  insufficient_data_actions = [module.aws_sns_topic.topic_arn]
}

#-----------------------------------
# CIS Log Group
#-----------------------------------

module "cis_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.1"

  name              = "${var.environment}-cis-log-group"
  retention_in_days = 120
}

#-----------------------------------
# CIS SNS Topic
#-----------------------------------

module "aws_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "6.1.1"
  subscriptions = [
    {
      protocol = "email"
      endpoint = "ms+cistest@mukeshsharma.dev"
    }
  ]

  name = "${var.environment}-cis-sns-topic"

  tags = {
    Terraform = "true"
    Environment = var.environment

  }
}

