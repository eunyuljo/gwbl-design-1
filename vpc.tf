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

  public_subnet_names = [
    "${local.gwlb_vpc.name}-Public-Subnet-A",
    "${local.gwlb_vpc.name}-Public-Subnet-B",
  ]

  tags = merge(var.common_tags, {
    project = local.gwlb_vpc.name
  })
}

#####################
# Consumer VPCs (VPC01, VPC02, VPC03)
#####################

# VPC module handles: VPC, IGW, Private Subnets, Private Route Tables
# Public Subnets are managed separately for per-AZ route table (matching original CFN)
module "consumer_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6"

  for_each = local.consumer_vpcs

  name = each.key
  cidr = each.value.cidr

  azs             = var.availability_zones
  private_subnets = each.value.private_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_igw         = false
  enable_nat_gateway = false

  private_subnet_names = [
    "${each.key}-Private-Subnet-A",
    "${each.key}-Private-Subnet-B",
  ]

  tags = merge(var.common_tags, {
    project = each.key
  })
}

###############################################
# Consumer VPC Internet Gateways (manual)
###############################################

resource "aws_internet_gateway" "consumer" {
  for_each = local.consumer_vpcs

  vpc_id = module.consumer_vpc[each.key].vpc_id

  tags = merge(var.common_tags, {
    Name = "${each.key}-IGW"
  })
}

###############################################
# Consumer VPC Public Subnets (per-AZ, manual)
###############################################

resource "aws_subnet" "consumer_public" {
  for_each = local.all_gwlb_endpoints

  vpc_id            = module.consumer_vpc[each.value.vpc_key].vpc_id
  cidr_block        = local.consumer_vpcs[each.value.vpc_key].public_subnets[each.value.az_index]
  availability_zone = var.availability_zones[each.value.az_index]

  tags = merge(var.common_tags, {
    Name = "${each.value.vpc_key}-Public-Subnet-${each.value.az_index == 0 ? "A" : "B"}"
  })
}

###############################################
# Consumer VPC Public Route Tables (per-AZ)
###############################################

resource "aws_route_table" "consumer_public" {
  for_each = local.all_gwlb_endpoints

  vpc_id = module.consumer_vpc[each.value.vpc_key].vpc_id

  tags = merge(var.common_tags, {
    Name = "${each.value.vpc_key}-Public-Subnet-${each.value.az_index == 0 ? "A" : "B"}-RT"
  })
}

resource "aws_route" "consumer_public_igw" {
  for_each = local.all_gwlb_endpoints

  route_table_id         = aws_route_table.consumer_public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.consumer[each.value.vpc_key].id
}

resource "aws_route_table_association" "consumer_public" {
  for_each = local.all_gwlb_endpoints

  subnet_id      = aws_subnet.consumer_public[each.key].id
  route_table_id = aws_route_table.consumer_public[each.key].id
}
