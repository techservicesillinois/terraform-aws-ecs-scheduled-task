data "aws_caller_identity" "current" {}

module "get-subnets" {
  source = "github.com/techservicesillinois/terraform-aws-util//modules/get-subnets?ref=v3.0.3"
  count  = local.subnet_type != null ? 1 : 0

  subnet_type = local.subnet_type
  vpc         = local.vpc
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
