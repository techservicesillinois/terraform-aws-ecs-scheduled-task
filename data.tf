data "aws_caller_identity" "current" {}

module "get-subnets" {
  source = "github.com/techservicesillinois/terraform-aws-util//modules/get-subnets?ref=v3.0.4"

  count       = var.network_configuration.subnet_type != null ? 1 : 0
  subnet_type = var.network_configuration.subnet_type
  vpc         = var.network_configuration.vpc
}

locals {
  module_subnet_ids = var.network_configuration.subnet_type != null ? try(module.get-subnets[0].subnets.ids, []) : []
  tags              = merge({ Name = var.name }, var.tags)
}

data "aws_ecs_cluster" "selected" {
  cluster_name = var.cluster
}

data "aws_security_groups" "selected" {
  count = length(var.security_groups)

  filter {
    name   = "group-name"
    values = var.security_groups
  }
}
