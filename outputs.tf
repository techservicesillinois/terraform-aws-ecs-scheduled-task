output "name" {
  value = var.name
}

output "task_definition_arn" {
  value = local.target_task_definition_arn
}

output "schedule_expression" {
  value = aws_cloudwatch_event_rule.default.schedule_expression
}

output "state" {
  value = aws_cloudwatch_event_rule.default.state
}
