# AWS Knowledge: AmazonSSMManagedInstanceCore replaces deprecated AmazonEC2RoleforSSM

#####################
# Appliance IAM Role
#####################

resource "aws_iam_role" "appliance" {
  name = "${local.gwlb_vpc.name}-ApplianceRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = var.common_tags
}

resource "aws_iam_role_policy" "appliance" {
  name = "AppServer"
  role = aws_iam_role.appliance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeNetworkInterfaces"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "appliance" {
  name = "${local.gwlb_vpc.name}-ApplianceProfile"
  path = "/"
  role = aws_iam_role.appliance.name

  tags = var.common_tags
}

#####################
# Consumer VPC SSM IAM Roles
#####################

resource "aws_iam_role" "ssm" {
  for_each = local.consumer_vpcs

  name = "${each.key}-SSMRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = var.common_tags
}

resource "aws_iam_instance_profile" "ssm" {
  for_each = local.consumer_vpcs

  name = "${each.key}-SSMProfile"
  path = "/"
  role = aws_iam_role.ssm[each.key].name

  tags = var.common_tags
}
