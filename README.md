# ecs-scheduled-task

[![Terraform actions status](https://github.com/techservicesillinois/terraform-aws-ecs-scheduled-task/workflows/terraform/badge.svg)](https://github.com/techservicesillinois/terraform-aws-ecs-scheduled-task/actions)

A module to supports the ability to schedule tasks utilizing AWS Cron Expressions.  
**NOTE:** Currently, this module does not response to scheduling tasks to  
CloudWatch Events in ECS.

Example Usage
----------------

```hcl
module "scheduledtask" {
  source = "git@github.com:techservicesillinois/terraform-aws-ecs-scheduled-task"

  name = "task-name"
  schedule_expression = "rate(1 hour)"

  network_configuration = {
    vpc = "vpc-name"
    tier = "nat"
    assign_public_ip = false
  }

}
```

Argument Reference
---------------------

### Required

* `name` -  The name of task to be scheduled. (Best practice would involve  
prefixing your service name to the task to uniquely identify the scheduled  
task)

* `schedule_expression` -  The scheduling expression.  
For example, cron(0 20 * * ? *) or rate(5 minutes).

### Optional

* `cluster` - A name of an ECS cluster. (Default = `default`)

* `desired_count` - The number of instances of the task definition to  
place and keep  running. (Default = `1`)

* `is_enabled` - Whether the rule should be enabled (Default = `true`).

* `launch_type` - The launch type on which to run the service. The valid  
values are EC2 and FARGATE. (Default = `FARGATE`)

* `network_configuration` -  A [Network Configuration](#network_configuration) block.  
This parameter is required for task definitions that use the `awsvpc` network mode
to receive their own Elastic Network Interface, and it is not supported for other  
network modes.

* `volume` - (Optional) A set of [volume blocks](#volume) that
containers in your task may use. Volume blocks are documented below.

* `task_definition` - (Optional) A [Task definition](#task_definition)
block. Task definition blocks are documented below

* `task_definition_arn` -  The family and revision (family:revision) or full ARN  
of the task definition that you want to run in your service. If given, the task  
definition block is ignored.

* `security_groups` - List of security group names (ID does not work!)

* `tags` - Tags to be applied to resources where supported.

network_configuration
-----------------------

A `network_configuration` block supports the following:

* assign_public_ip (optional) - Default to `false`

* `tier` - (Required) A subnet tier tag (e.g., public, private, nat)  
to determine subnets to be associated with the task orservice.

* `vpc` - (Required) The name of the virtual private cloud to be associated  
with the task or service. **NOTE:** Required when using `tier`.

* `subnets` - (Required) The subnet IDs to associated with the task or service.  
**NOTE:** Optional when using `tier`.

`task_definition`
-----------------

If a `task_definition_arn` is not given, a container definition will be created for the service. The name of the automatically created container definition is the same as the ECS service name.
The created container definition may optionally be further modified by specifying a `task_definition` block with one of more of the following options:

* `container_definition_file` - (Optional) A file containing a list of valid [container
definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions)
provided as a single JSON document. See
[Example Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/example_task_definitions.html)
for example container definitions, note that _only_ the content of the `containerDefinitions` key
in these example task definitions belongs in the specified `container_definition_file`.
The default filename is `containers.json`.

* `task_role_arn` - (Optional) The ARN of an IAM role that allows
your Amazon ECS container task to make calls to other AWS services.

* `network_mode` - (Optional) The Docker networking mode to use for
the containers in the task. The valid values are `none`, `bridge`,
`awsvpc`, and `host`.

* `cpu` - (Optional) The number of
[cpu units](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)
used by the task.  Supported for FARGATE only, defaults to 256 (0.25 vCPU).

* `memory` - (Optional) The amount (in MiB) of
[memory](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)
used by the task. Supported for FARGATE only, defaults to 512.

`volume`
--------

A `volume` block supports the following:

* `name` - (Required) The name of the volume. This name is referenced
in the `sourceVolume` parameter of container definition in the
`mountPoints` section.

* `host_path` - (Optional) The path on the host container instance
that is presented to the container. If not set, ECS will create a
non persistent data volume that starts empty and is deleted after
the task has finished.

* `docker_volume_configuration` - (Optional, but see note) Used to configure a [Docker volume](#docker_volume_configuration). **NOTE:** Due to limitations in Terraform object typing, either a valid `docker_volume_configuration` map or the value `null` must be specified.

* `efs_volume_configuration` - (Optional, but see note) Used to configure an [EFS volume](#efs_volume_configuration). **NOTE:** Due to limitations in Terraform object typing, either a valid `efs_volume_configuration` map or the value `null` must be specified.

```
volume = [
    {
      name      = "docker-volume"
      host_path = null

      docker_volume_configuration = null   # Needs to be specified as null, even if not used.
      efs_volume_configuration    = null   # Needs to be specified as null, even if not used.
    }
 ]
```

`docker_volume_configuration`
--------

A `docker_volume_configuration` block appears within a [`volume`](#volume) block, and supports the following:

* `scope` - (Optional) The scope for the Docker volume, which determines its lifecycle, either task or shared. Docker volumes that are scoped to a task are automatically provisioned when the task starts and destroyed when the task stops. Docker volumes that are scoped as shared persist after the task stops.

* `autoprovision` - (Optional) If this value is true, the Docker volume is created if it does not already exist. Note: This field is only used if the scope is shared.

* `driver` - (Optional) The Docker volume driver to use. The driver value must match the driver name provided by Docker because it is used for task placement.

* `driver_opts` - (Optional) A map of Docker driver specific options.

* `labels - (Optional) A map of custom metadata to add to your Docker volume.

For more information, see [Specifying a Docker volume in your Task Definition Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-volumes.html#specify-volume-config)

`efs_volume_configuration`
--------

An `efs_volume_configuration` block appears within a [`volume`](#volume) block, and supports the following:

* `file_system_id` - (Required) The ID of the EFS File System.

* `root_directory` - (Optional) The path to mount on the host.


```
volume = [
    {
      name = "efs-volume"
      host_path = null

      docker_volume_configuration = null

      efs_volume_configuration = {
        file_system_id = "fs-012345678"
        root_directory = null
      }
    }
 ]
```

For more information, see [Specifying an Amazon EFS File System in your Task Definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html#specify-efs-config).

Attributes Reference
--------------------

The following attributes are exported:

* `is_enabled` – Is the task enabled.

* `name` - The name of the scheduled task.

* `schedule_expression` - The cron like expression that determines  
when your scheduled task will run.

* `task_definition_arn` - Full ARN of the Task Definition created
for the scheduled task.
