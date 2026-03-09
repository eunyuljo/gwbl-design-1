#####################
# GWLB VPC Outputs
#####################

output "gwlb_vpc_id" {
  description = "GWLB VPC ID"
  value       = module.gwlb_vpc.vpc_id
}

output "gwlb_vpc_public_subnets" {
  description = "GWLB VPC public subnet IDs"
  value       = module.gwlb_vpc.public_subnets
}

output "vpc_endpoint_service_name" {
  description = "VPC Endpoint Service Name"
  value       = aws_vpc_endpoint_service.gwlb.service_name
}

output "gwlb_arn" {
  description = "GWLB ARN"
  value       = aws_lb.gwlb.arn
}

output "appliance_public_ips" {
  description = "Appliance instance public IPs"
  value = {
    for k, v in aws_instance.appliance : k => v.public_ip
  }
}

#####################
# Consumer VPC Outputs
#####################

output "consumer_vpc_ids" {
  description = "Consumer VPC IDs"
  value = {
    for k, v in module.consumer_vpc : k => v.vpc_id
  }
}

output "consumer_private_subnet_ids" {
  description = "Consumer VPC private subnet IDs"
  value = {
    for k, v in module.consumer_vpc : k => v.private_subnets
  }
}

output "private_instance_ids" {
  description = "Private instance IDs"
  value = {
    for k, v in aws_instance.private : k => v.id
  }
}
