# Smooth transition for infrastructure created by old module versions.

moved {
  from = aws_ecs_task_definition.ec2[0]
  to   = aws_ecs_task_definition.default["EC2"]
}

moved {
  from = aws_ecs_task_definition.fargate[0]
  to   = aws_ecs_task_definition.default["FARGATE"]
}

resource "aws_ecs_task_definition" "default" {
  for_each = toset(var.task_definition_arn == null ? [var.launch_type] : [])

  execution_role_arn = format(
    "arn:aws:iam::%s:role/ecsTaskExecutionRole",
    data.aws_caller_identity.current.account_id,
  )
  family                   = var.name
  container_definitions    = local.container_definitions
  cpu                      = var.task_definition.cpu
  memory                   = var.task_definition.memory
  network_mode             = var.task_definition.network_mode
  requires_compatibilities = var.launch_type == "FARGATE" ? ["FARGATE"] : ["EC2"]
  tags                     = local.tags
  task_role_arn            = var.task_definition.task_role_arn

  dynamic "volume" {
    for_each = var.volume
    content {
      host_path = volume.value.host_path
      name      = volume.value.name

      dynamic "docker_volume_configuration" {
        for_each = volume.value.docker_volume_configuration != null ? [volume.value.docker_volume_configuration] : []
        content {
          autoprovision = docker_volume_configuration.value.autoprovision
          driver        = docker_volume_configuration.value.driver
          driver_opts   = docker_volume_configuration.value.driver_opts
          labels        = docker_volume_configuration.value.labels
          scope         = docker_volume_configuration.value.scope
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id = efs_volume_configuration.value.file_system_id
          root_directory = efs_volume_configuration.value.root_directory
        }
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "default" {
  state               = var.state
  name                = var.name
  schedule_expression = var.schedule_expression
  tags                = local.tags
}

resource "aws_cloudwatch_event_target" "default" {
  arn       = data.aws_ecs_cluster.selected.id
  role_arn  = aws_iam_role.ecs_events_role.arn
  rule      = aws_cloudwatch_event_rule.default.name
  target_id = var.name

  ecs_target {
    launch_type         = var.launch_type
    propagate_tags      = "TASK_DEFINITION"
    tags                = local.tags
    task_count          = var.desired_count
    task_definition_arn = local.target_task_definition_arn

    network_configuration {
      subnets = local.all_subnets
      security_groups = concat(
        [aws_security_group.default.id],
        flatten(data.aws_security_groups.selected.*.ids),
      )
    }
  }
}

# TODO: Does this need to be made?

resource "aws_security_group" "default" {
  name   = var.name
  tags   = local.tags
  vpc_id = module.get-subnets[0].vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_events_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_events_policy.json
  name               = var.name
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "events_service_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
  role       = aws_iam_role.ecs_events_role.name
}

data "aws_iam_policy_document" "ecs_events_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}
