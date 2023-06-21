variable "cluster" {
  description = "ECS cluster name"
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
  description = "Launch type for the service. Valid values are EC2 and FARGATE."
  default     = "FARGATE"

  validation {
    condition     = try(contains(["EC2", "FARGATE"], var.launch_type), true)
    error_message = "The 'launch_type' is not one of the valid values 'EC2' or 'FARGATE'."
  }
}

variable "name" {
  description = "ECS service name"
}

variable "network_configuration" {
  description = "Network configuration block"
  type = object({
    assign_public_ip     = optional(bool, false)
    ports                = optional(list(number), [])
    security_group_ids   = optional(list(string), [])
    security_group_names = optional(list(string), [])
    subnet_ids           = optional(list(string), [])
    subnet_type          = optional(string)
    vpc                  = optional(string)
  })
  default = null

  # Validate that either subnet_ids or both subnet_type and vpc are defined.

  validation {
    # TODO: This validation rule should be made more robust.
    condition     = var.network_configuration == null || can(length(var.network_configuration.subnet_ids) > 0 || (var.network_configuration.subnet_type != null && var.network_configuration.vpc != null))
    error_message = "The 'network_configuration' block must define both 'subnet_type' and 'vpc', or must define 'subnet_ids'."
  }

  # Validate subnet_type (if specified).

  validation {
    condition     = try(contains(["campus", "private", "public"], var.network_configuration.subnet_type), true)
    error_message = "The 'subnet_type' specified in the 'network_configuration' block is not one of the valid values 'campus', 'private', or 'public'."
  }
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
}

variable "task_definition" {
  description = "Task definition block"
  type = object({
    container_definition_file = optional(string)
    cpu                       = optional(number)           # Required for Fargate.
    memory                    = optional(number)           # Required for Fargate.
    network_mode              = optional(string, "awsvpc") # Normal use case.
    task_role_arn             = optional(string)
    template_variables = optional(object({
      docker_tag  = string
      region      = string
      registry_id = string
    }))
  })
  default = null
}

variable "task_definition_arn" {
  description = "The family and revision (family:revision) or full ARN of a task definition for the ECS service"
  default     = null
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

# Debugging.

variable "_debug" {
  description = "Produce debug output (boolean)"
  type        = bool
  default     = false
}
