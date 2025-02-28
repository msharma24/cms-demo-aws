module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "4.1.0"

  zones = {
    "${var.route53_dns_zone_name}" = {
      comment = "Managed by Terraform - ${var.environment} environment"
      tags = {
        Environment = var.environment
        Terraform   = "true"
        Project     = "cms"
      }
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
  }
}

# module "records" {
#   source  = "terraform-aws-modules/route53/aws//modules/records"
#   version = "~> 3.0"

#   zone_name = var.route53_dns_zone_name

#   records = [
#     {
#       name    = ""  # apex domain
#       type    = "A"
#       alias   = {
#         name    = module.alb.lb_dns_name
#         zone_id = module.alb.lb_zone_id
#         evaluate_target_health = true
#       }
#     },
#     {
#       name    = "www"
#       type    = "A"
#       alias   = {
#         name    = module.alb.lb_dns_name
#         zone_id = module.alb.lb_zone_id
#         evaluate_target_health = true
#       }
#     }
#   ]

#   depends_on = [module.zones]
# }

# # Outputs
# output "route53_zone_name" {
#   description = "Domain name of the Route53 zone"
#   value       = var.route53_dns_zone_name
# }

# output "route53_zone_id" {
#   description = "ID of the Route53 zone"
#   value       = module.zones.route53_zone_zone_id[var.route53_dns_zone_name]
# }

# output "route53_name_servers" {
#   description = "Name servers of the Route53 zone"
#   value       = module.zones.route53_zone_name_servers[var.route53_dns_zone_name]
# } 

