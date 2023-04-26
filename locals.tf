locals {
  # FIXME: is target_task_definition_arn redundant?
  task_definition_arn        = var.task_definition_arn != null ? var.task_definition_arn : aws_ecs_task_definition.default[var.launch_type].arn
  target_task_definition_arn = var.task_definition_arn == null ? local.task_definition_arn : var.task_definition_arn
}

locals {
  all_subnets = distinct(concat(local.module_subnet_ids, try(var.network_configuration.subnet_ids, [])))
}

# Compute container definition file name, then determine whether it's
# a template or simply a json file.

locals {
  container_definition_file = var.task_definition.template_variables != null ? (var.task_definition.container_definition_file != null ? var.task_definition.container_definition_file : "containers.json.tftpl") : (var.task_definition.container_definition_file != null ? var.task_definition.container_definition_file : "containers.json")
  container_definitions     = endswith(local.container_definition_file, ".tftpl") ? try(templatefile(local.container_definition_file, var.task_definition.template_variables), false) : file(local.container_definition_file)
}
