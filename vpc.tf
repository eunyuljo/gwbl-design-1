# AWS Knowledge: GWLB requires multi-AZ deployment for high availability
# Terraform Registry: terraform-aws-modules/vpc/aws v6.6.0

#####################
# GWLB VPC
#####################

module "gwlb_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  name = local.gwlb_vpc.name
  cidr = local.gwlb_vpc.cidr

  azs            = var.availability_zones
  public_subnets = local.gwlb_vpc.public_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name    = local.gwlb_vpc.name
    project = local.gwlb_vpc.name
  })
}

#####################
# Consumer VPCs (VPC01, VPC02, VPC03)
#####################

module "consumer_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  for_each = local.consumer_vpcs

  name = each.key
  cidr = each.value.cidr

  azs             = var.availability_zones
  public_subnets  = each.value.public_subnets
  private_subnets = each.value.private_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw         = true
  enable_nat_gateway = false

  tags = merge(var.common_tags, {
    Name    = each.key
    project = each.key
  })
}
