environment = "ccx"

aws_region = "ap-southeast-2"

vpc_cidr_range        = "172.17.0.0/20"
private_subnets_list  = ["172.17.0.0/24", "172.17.1.0/24"]
public_subnets_list   = ["172.17.3.0/24", "172.17.4.0/24"]
database_subnets_list = ["172.17.6.0/24", "172.17.7.0/24"]


route53_dns_zone_name = "ccx.loremimpsum.com"
