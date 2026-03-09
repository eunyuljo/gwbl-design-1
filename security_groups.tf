# Terraform Registry: terraform-aws-modules/security-group/aws v5.3.1

#####################
# Appliance SG (GWLB VPC)
#####################

module "appliance_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  name        = "${local.gwlb_vpc.name}-ApplianceEC2SG"
  description = "Open-up ports for ICMP and SSH,HTTP/S,UDP 6081 from All network"
  vpc_id      = module.gwlb_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "all-icmp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "SSH"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS"
    },
    {
      from_port   = 6081
      to_port     = 6081
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
      description = "GENEVE"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(var.common_tags, {
    Name = "${local.gwlb_vpc.name}-Appliance-SG"
  })
}

#####################
# Private EC2 SG (Consumer VPCs)
#####################

module "private_ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  for_each = local.consumer_vpcs

  name        = "${each.key}-PrivateEC2SG"
  description = "Open-up ports for ICMP and SSH,HTTP/S from All network"
  vpc_id      = module.consumer_vpc[each.key].vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "all-icmp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "SSH"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(var.common_tags, {
    Name = "${each.key}-PrivateSG"
  })
}

#####################
# SSM Endpoint SG (Consumer VPCs)
#####################

module "ssm_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3"

  for_each = local.consumer_vpcs

  name        = "${each.key}-SSMSG"
  description = "Open-up ports for HTTP/S from All network"
  vpc_id      = module.consumer_vpc[each.key].vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = merge(var.common_tags, {
    Name = "${each.key}-SSMSG"
  })
}
