data "aws_subnet" "selected" {
  count = length(var.network_configuration) > 0 ? 1 : 0
  id    = local.all_subnets[0]
}

data "aws_vpc" "selected" {
  count = local.tier != "" ? 1 : 0

  tags = {
    Name = local.vpc
  }
}

data "aws_subnet_ids" "selected" {
  count  = local.tier != "" ? 1 : 0
  vpc_id = data.aws_vpc.selected[0].id

  tags = {
    Tier = local.tier
  }
}

data "aws_caller_identity" "current" {}

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
