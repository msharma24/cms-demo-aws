module "test_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "${var.environment}/test_instance"
  instance_count = 1

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  monitoring             = true
  vpc_security_group_ids = [module.ssh_security_group.security_group_id]
  subnet_id              = module.vpc.private_subnets[1]
  iam_instance_profile   = module.test_instance_iam_assumable_role.iam_instance_profile_id
  #user_data              = base64encode(templatefile("${path.module}/init.tfpl", local.efs_vars)) 
  associate_public_ip_address = true


  # user_data              = <<EOF                                                                 
  # #!/bin/bash                                                                                    
  # sleep 60;                                                                                      
  # yum install  -y                                                                                
  # sleep 5;                                                                                       
  # yum install nc telnet -y                                                                       
  # EOF                                                                                            

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 8
    instance_metadata_tags      = "enabled"
  }


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "amzn2-ami-hvm*"
}



module "ssh_security_group" {

  source = "terraform-aws-modules/security-group/aws//modules/ssh"

  name        = "vpc-ssh-22-sg"
  description = "Security group for ssh  within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [
    module.vpc.vpc_cidr_block,

  ]
}
