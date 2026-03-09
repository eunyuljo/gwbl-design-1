# AWS Knowledge: GWLB uses GENEVE protocol (UDP 6081) for transparent inspection
# No official terraform-aws-modules for GWLB — using raw resources

#####################
# Gateway Load Balancer
#####################

resource "aws_lb" "gwlb" {
  name               = "GWLB"
  load_balancer_type = "gateway"
  subnets            = module.gwlb_vpc.public_subnets

  tags = merge(var.common_tags, {
    Name = "${local.gwlb_vpc.name}-GWLB"
  })
}

#####################
# Target Group
#####################

resource "aws_lb_target_group" "gwlb" {
  name     = "GWLB-TG"
  port     = 6081
  protocol = "GENEVE"
  vpc_id   = module.gwlb_vpc.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
  }

  deregistration_delay = 20
  target_type          = "instance"

  tags = merge(var.common_tags, {
    Name = "${local.gwlb_vpc.name}-GWLB-Target-Group"
  })
}

resource "aws_lb_target_group_attachment" "appliance" {
  for_each = local.appliance_instances

  target_group_arn = aws_lb_target_group.gwlb.arn
  target_id        = aws_instance.appliance[each.key].id
}

#####################
# Listener
#####################

resource "aws_lb_listener" "gwlb" {
  load_balancer_arn = aws_lb.gwlb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb.arn
  }
}

#####################
# VPC Endpoint Service
#####################

resource "aws_vpc_endpoint_service" "gwlb" {
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
  acceptance_required        = false

  tags = merge(var.common_tags, {
    Name = "${local.gwlb_vpc.name}-Endpoint-Service"
  })
}
