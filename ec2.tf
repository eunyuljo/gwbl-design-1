#####################
# Appliance Instances (GWLB VPC)
#####################

resource "aws_instance" "appliance" {
  for_each = local.appliance_instances

  ami                    = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_type
  subnet_id              = module.gwlb_vpc.public_subnets[each.value.subnet_index]
  private_ip             = each.value.private_ip
  vpc_security_group_ids = [module.appliance_sg.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.appliance.name

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    iops                  = 3000
    delete_on_termination = true
    encrypted             = true
  }

  user_data = file("${path.module}/scripts/appliance_userdata.sh")

  tags = merge(var.common_tags, {
    Name = "${local.gwlb_vpc.name}-Appliance-${each.value.private_ip}"
  })
}

#####################
# Private Instances (Consumer VPCs)
#####################

resource "aws_instance" "private" {
  for_each = local.all_private_instances

  ami                         = data.aws_ssm_parameter.ami.value
  instance_type               = var.instance_type
  subnet_id                   = module.consumer_vpc[each.value.vpc_key].private_subnets[each.value.subnet_index]
  private_ip                  = each.value.private_ip
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.private_ec2_sg[each.value.vpc_key].security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ssm[each.value.vpc_key].name

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    iops                  = 3000
    delete_on_termination = true
    encrypted             = true
  }

  user_data = file("${path.module}/scripts/webserver_userdata.sh")

  tags = merge(var.common_tags, {
    Name = "${each.value.vpc_key}-Private-${each.value.private_ip}"
  })
}
