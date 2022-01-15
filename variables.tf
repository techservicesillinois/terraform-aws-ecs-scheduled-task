#### Required

variable "name" {
  description = "The name of the ECS service"
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
}

#### Optional

variable "cluster" {
  description = "A name of an ECS cluster"
  default     = "default"
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running"
  default     = 1
}

variable "is_enabled" {
  description = "Whether the rule should be enabled (defaults to true)."
  default     = true
}

variable "launch_type" {
  description = "The launch type on which to run the service. The valid values are EC2 and FARGATE."
  default     = "FARGATE"
}

variable "network_configuration" {
  description = "A network configuration block"
  type        = map(string)
  default     = {}
}

variable "task_definition" {
  description = "Task definition block (map)"
  type        = map(string)
  default     = {}
}

variable "task_definition_arn" {
  description = "The ARN of the task definition to use if the event target is an Amazon ECS cluster."
  default     = ""
}

variable "security_groups" {
  description = "List of security group names (ID does not work!)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to be applied to resources where supported"
  type        = map(string)
  default     = {}
}

variable "volume" {
  description = "A list of volume blocks that containers in your task may use."
  type = list(object({
    name      = string
    host_path = string
    docker_volume_configuration = object({
      scope         = string
      autoprovision = bool
      driver        = string
      driver_opts   = map(string)
      labels        = map(string)
    })
    efs_volume_configuration = object({
      file_system_id = string
      root_directory = string
    })
  }))
  default = []
}
