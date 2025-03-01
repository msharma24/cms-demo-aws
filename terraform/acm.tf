module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name = var.route53_dns_zone_name
  zone_id    = module.zones.route53_zone_zone_id[var.route53_dns_zone_name]

  subject_alternative_names = [
    "*.${var.route53_dns_zone_name}",    # Wildcard for all subdomains
    "www.${var.route53_dns_zone_name}",   # Explicit www subdomain
  ]

  validation_method = "DNS"
  wait_for_validation = true

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "cms"
    Service     = "wordpress"
  }

  depends_on = [module.zones]
}

# Output the certificate ARN for use in ALB configuration
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.acm.acm_certificate_arn
}

# Output the certificate validation status
output "acm_certificate_status" {
  description = "Status of the ACM certificate validation"
  value       = module.acm.acm_certificate_status
}
