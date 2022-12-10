provider "aws" {
  region = var.region
}

locals {
  name = "tfc-audit-trail"
}

resource "aws_cloudwatch_log_group" "tfc-audit-trail" {
  name = local.name
}

resource "aws_cloudwatch_log_stream" "tfc-audit-trail" {
  name           = local.name
  log_group_name = aws_cloudwatch_log_group.tfc-audit-trail.name
}

resource "aws_ssm_parameter" "tfc-org-token" {
  name  = "tfc-org-token-${local.name}"
  type  = "SecureString"
  tier  = "Standard"
  value = var.TFC_ORG_TOKEN
}

resource "aws_ecs_cluster" "tfc-audit-trail-cluster" {
  name = local.name
}

resource "aws_ecs_task_definition" "tfc-audit-trail" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  volume {
    name = "vector-conf-vol"
  }
  # the execution role is for the ecs agent on the underlying EC2 instances to perform AWS API calls
  # mainly needed for the awslogs driver we use to capture crash/error logs for vector
  # and retrieving SSM parameters, which we use for passing secrets
  execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
  # the task role is for applications running within containers to make AWS API calls
  task_role_arn = aws_iam_role.vector.arn

  container_definitions = jsonencode([
    {
      name      = local.name
      image     = "timberio/vector:latest-alpine"
      essential = true
      secrets = [
        {
          name      = "TFC_ORG_TOKEN"
          valueFrom = aws_ssm_parameter.tfc-org-token.arn
        }
      ]
      dependsOn = [
        {
          condition     = "COMPLETE"
          containerName = "${local.name}-config"
        }
      ]
      mountPoints = [
        {
          containerPath = "/etc/vector"
          sourceVolume  = "vector-conf-vol"
        }
      ]
      # use the aws log driver to ensure delivery of debug/crash information to cloudwatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.tfc-audit-trail.name,
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "vector-debug"
        }
      }
    },
    # this is a sidecar container that writes the vector config into a shared volume
    # the vector container will wait for this container to complete
    {
      name      = "${local.name}-config"
      image     = "public.ecr.aws/docker/library/bash:latest"
      essential = false
      command = [
        "-c",
        "echo $DATA | base64 -d > /etc/vector/vector.toml"
      ]
      environment = [
        {
          name = "DATA"
          value = base64encode(templatefile("${path.module}/vector.toml.tftpl", {
            endpoint             = var.tfc_audit_trail_url
            scrape_interval_secs = var.scrape_interval_secs
            group_name           = aws_cloudwatch_log_group.tfc-audit-trail.name
            region               = var.region
            stream_name          = aws_cloudwatch_log_stream.tfc-audit-trail.name
            page_size            = var.page_size
            cache_num_events     = var.deduplication_cache_size
          }))
        }
      ]
      mountPoints = [
        {
          containerPath = "/etc/vector"
          sourceVolume  = "vector-conf-vol"
        }
      ]
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "tfc-audit-trail-service" {
  name            = local.name
  cluster         = aws_ecs_cluster.tfc-audit-trail-cluster.id
  task_definition = aws_ecs_task_definition.tfc-audit-trail.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets          = module.tfc-audit-trail-vpc.public_subnets
  }
  wait_for_steady_state = true
}
