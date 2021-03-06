# task_defintion_arn
locals {
  task_definition_arn = element(
    concat(
      aws_ecs_task_definition.fargate.*.arn,
      aws_ecs_task_definition.ec2.*.arn,
      [""],
    ),
    0,
  )

  target_task_definition_arn = var.task_definition_arn == "" ? local.task_definition_arn : var.task_definition_arn
}

# subnet ids parsed from "private, public, or nat" tier
locals {
  all_subnets = distinct(
    concat(flatten(data.aws_subnet_ids.selected.*.ids), local.subnets),
  )
}

# task_definition map
locals {
  container_definition_file = lookup(
    var.task_definition,
    "container_definition_file",
    "containers.json",
  )

  cpu           = lookup(var.task_definition, "cpu", 256)
  memory        = lookup(var.task_definition, "memory", 512)
  network_mode  = lookup(var.task_definition, "network_mode", "awsvpc")
  task_role_arn = lookup(var.task_definition, "task_role_arn", "")
}

# network_configuration map
locals {
  assign_public_ip = lookup(var.network_configuration, "assign_public_ip", false)
  tier             = lookup(var.network_configuration, "tier", "")
  vpc              = lookup(var.network_configuration, "vpc", "")
  subnets          = compact(split(" ", lookup(var.network_configuration, "subnets", "")))
}
