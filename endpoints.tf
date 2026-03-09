# AWS Knowledge: GWLB endpoints must be per-AZ for symmetric routing
# Consumer VPCs reference GWLB VPC Endpoint Service directly

###############################################
# IGW Ingress Route Tables (per consumer VPC)
###############################################

resource "aws_route_table" "igw_ingress" {
  for_each = local.consumer_vpcs

  vpc_id = module.consumer_vpc[each.key].vpc_id

  tags = merge(var.common_tags, {
    Name = "${each.key}-IGW-Ingress-RT"
  })
}

resource "aws_route_table_association" "igw_ingress" {
  for_each = local.consumer_vpcs

  gateway_id     = aws_internet_gateway.consumer[each.key].id
  route_table_id = aws_route_table.igw_ingress[each.key].id
}

###############################################
# GWLB VPC Endpoints (per consumer VPC, per AZ)
###############################################

resource "aws_vpc_endpoint" "gwlb" {
  for_each = local.all_gwlb_endpoints

  vpc_id            = module.consumer_vpc[each.value.vpc_key].vpc_id
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.consumer_public[each.key].id]

  tags = merge(var.common_tags, {
    Name = "${each.value.vpc_key}-GWLB-Endpoint-${var.availability_zones[each.value.az_index]}"
  })
}

###############################################
# Routes: Private Subnet -> GWLB Endpoint
###############################################

resource "aws_route" "private_to_gwlb" {
  for_each = local.all_gwlb_endpoints

  route_table_id         = module.consumer_vpc[each.value.vpc_key].private_route_table_ids[each.value.az_index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.gwlb[each.key].id
}

###############################################
# Routes: IGW Ingress -> GWLB Endpoint
# (return traffic to private subnets via GWLB)
###############################################

resource "aws_route" "igw_to_gwlb" {
  for_each = local.all_gwlb_endpoints

  route_table_id         = aws_route_table.igw_ingress[each.value.vpc_key].id
  destination_cidr_block = local.consumer_vpcs[each.value.vpc_key].private_subnets[each.value.az_index]
  vpc_endpoint_id        = aws_vpc_endpoint.gwlb[each.key].id
}

###############################################
# SSM VPC Interface Endpoints (per consumer VPC)
###############################################

resource "aws_vpc_endpoint" "ssm" {
  for_each = local.consumer_vpcs

  vpc_id              = module.consumer_vpc[each.key].vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.consumer_vpc[each.key].private_subnets
  security_group_ids  = [module.ssm_sg[each.key].security_group_id]

  tags = merge(var.common_tags, {
    Name = "${each.key}-SSM-Endpoint"
  })
}

resource "aws_vpc_endpoint" "ssm_messages" {
  for_each = local.consumer_vpcs

  vpc_id              = module.consumer_vpc[each.key].vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.consumer_vpc[each.key].private_subnets
  security_group_ids  = [module.ssm_sg[each.key].security_group_id]

  tags = merge(var.common_tags, {
    Name = "${each.key}-SSMMessages-Endpoint"
  })
}
