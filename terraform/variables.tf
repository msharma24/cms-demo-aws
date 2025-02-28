variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name for tagging and resource naming"
  type        = string
}

variable "vpc_cidr_range" {
  description = "CIDR range for the VPC"
  type        = string
}

variable "private_subnets_list" {
  description = "List of CIDR ranges for private subnets"
  type        = list(string)
}

variable "public_subnets_list" {
  description = "List of CIDR ranges for public subnets"
  type        = list(string)
}

variable "database_subnets_list" {
  description = "List of CIDR ranges for database subnets"
  type        = list(string)
}
