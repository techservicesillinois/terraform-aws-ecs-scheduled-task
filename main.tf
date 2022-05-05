resource "aws_ecs_task_definition" "fargate" {
  count = var.task_definition_arn == "" && var.launch_type == "FARGATE" ? 1 : 0

  family                = var.name
  container_definitions = file(local.container_definition_file)
  task_role_arn         = local.task_role_arn

  execution_role_arn = format(
    "arn:aws:iam::%s:role/ecsTaskExecutionRole",
    data.aws_caller_identity.current.account_id,
  )

  network_mode = local.network_mode

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

  cpu                      = local.cpu
  memory                   = local.memory
  requires_compatibilities = ["FARGATE"]

  tags = merge({ "Name" = var.name }, var.tags)
}

resource "aws_ecs_task_definition" "ec2" {
  count = var.task_definition_arn == "" && var.launch_type == "EC2" ? 1 : 0

  family                = var.name
  container_definitions = file(local.container_definition_file)
  task_role_arn         = local.task_role_arn

  execution_role_arn = format(
    "arn:aws:iam::%s:role/ecsTaskExecutionRole",
    data.aws_caller_identity.current.account_id,
  )

  network_mode = local.network_mode

  cpu                      = local.cpu
  memory                   = local.memory
  requires_compatibilities = ["EC2"]

  tags = merge({ "Name" = var.name }, var.tags)
}

resource "aws_cloudwatch_event_rule" "default" {
  name                = var.name
  schedule_expression = var.schedule_expression
  is_enabled          = var.is_enabled

  tags = merge({ "Name" = var.name }, var.tags)
}

resource "aws_cloudwatch_event_target" "default" {
  target_id = var.name
  rule      = aws_cloudwatch_event_rule.default.name
  arn       = data.aws_ecs_cluster.selected.id
  role_arn  = aws_iam_role.ecs_events_role.arn

  ecs_target {
    task_count          = var.desired_count
    task_definition_arn = local.target_task_definition_arn
    launch_type         = var.launch_type

    network_configuration {
      subnets = local.all_subnets
      security_groups = concat(
        [aws_security_group.default.id],
        flatten(data.aws_security_groups.selected.*.ids),
      )
    }
  }
}

resource "aws_security_group" "default" {
  name   = var.name
  vpc_id = module.get-subnets[0].vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = var.name }, var.tags)
}

### Boiler plate role for ecs events. Role name needs to be unique. ---------
resource "aws_iam_role" "ecs_events_role" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.ecs_events_policy.json

  tags = merge({ "Name" = var.name }, var.tags)
}

resource "aws_iam_role_policy_attachment" "events_service_role_attachment" {
  role       = aws_iam_role.ecs_events_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
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
