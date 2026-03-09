# GWLB VPC configuration
locals {
  gwlb_vpc = {
    name            = "GWLBVPC"
    cidr            = "10.254.0.0/16"
    public_subnets  = ["10.254.11.0/24", "10.254.12.0/24"]
  }

  appliance_instances = {
    "appliance-1" = { subnet_index = 0, private_ip = "10.254.11.101" }
    "appliance-2" = { subnet_index = 0, private_ip = "10.254.11.102" }
    "appliance-3" = { subnet_index = 1, private_ip = "10.254.12.101" }
    "appliance-4" = { subnet_index = 1, private_ip = "10.254.12.102" }
  }
}

# Consumer VPCs configuration — for_each source
locals {
  consumer_vpcs = {
    "VPC01" = {
      cidr            = "10.1.0.0/16"
      public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
      private_subnets = ["10.1.21.0/24", "10.1.22.0/24"]
      private_instances = {
        "private-a-1" = { subnet_index = 0, private_ip = "10.1.21.101" }
        "private-a-2" = { subnet_index = 0, private_ip = "10.1.21.102" }
        "private-b-1" = { subnet_index = 1, private_ip = "10.1.22.101" }
        "private-b-2" = { subnet_index = 1, private_ip = "10.1.22.102" }
      }
    }
    "VPC02" = {
      cidr            = "10.2.0.0/16"
      public_subnets  = ["10.2.11.0/24", "10.2.12.0/24"]
      private_subnets = ["10.2.21.0/24", "10.2.22.0/24"]
      private_instances = {
        "private-a-1" = { subnet_index = 0, private_ip = "10.2.21.101" }
        "private-a-2" = { subnet_index = 0, private_ip = "10.2.21.102" }
        "private-b-1" = { subnet_index = 1, private_ip = "10.2.22.101" }
        "private-b-2" = { subnet_index = 1, private_ip = "10.2.22.102" }
      }
    }
    "VPC03" = {
      cidr            = "10.3.0.0/16"
      public_subnets  = ["10.3.11.0/24", "10.3.12.0/24"]
      private_subnets = ["10.3.21.0/24", "10.3.22.0/24"]
      private_instances = {
        "private-a-1" = { subnet_index = 0, private_ip = "10.3.21.101" }
        "private-a-2" = { subnet_index = 0, private_ip = "10.3.21.102" }
        "private-b-1" = { subnet_index = 1, private_ip = "10.3.22.101" }
        "private-b-2" = { subnet_index = 1, private_ip = "10.3.22.102" }
      }
    }
  }

  # Flatten private instances for for_each: "VPC01/private-a-1" => { vpc_key, ... }
  all_private_instances = merge([
    for vpc_key, vpc in local.consumer_vpcs : {
      for inst_key, inst in vpc.private_instances :
      "${vpc_key}/${inst_key}" => {
        vpc_key      = vpc_key
        subnet_index = inst.subnet_index
        private_ip   = inst.private_ip
      }
    }
  ]...)

  # Flatten GWLB endpoints: "VPC01/0", "VPC01/1" => { vpc_key, az_index }
  all_gwlb_endpoints = merge([
    for vpc_key, vpc in local.consumer_vpcs : {
      for idx in range(length(var.availability_zones)) :
      "${vpc_key}/${idx}" => {
        vpc_key  = vpc_key
        az_index = idx
      }
    }
  ]...)
}
