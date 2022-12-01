provider "aws" {
  region = var.region
}

resource "aws_cloudwatch_log_group" "tfc-audit-trail" {
  name = "tfc-audit-trail"
}

resource "aws_cloudwatch_log_stream" "tfc-audit-trail" {
  name           = "tfc-audit-trail"
  log_group_name = aws_cloudwatch_log_group.tfc-audit-trail.name
}

resource "aws_ecs_cluster" "tfc-audit-trail-cluster" {
  name = "tfc-audit-trail-cluster"
}

resource "aws_ecs_task_definition" "tfc-audit-trail" {
  family                   = "tfc-audit-trail"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  volume {
    name = "vector-conf-vol"
  }
  # the execution role is for FARGATE/underlying EC2 instances to perform API calls
  # mainly needed for the awslogs driver we use to capture crash/error logs for vector
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  # the task role is for applications running within containers to make AWS API calls
  task_role_arn = aws_iam_role.vector-cloudwatch-logs.arn

  container_definitions = jsonencode([
    {
      name      = "tfc-audit-trail"
      image     = "timberio/vector:latest-alpine"
      essential = true
      dependsOn = [
        {
          condition     = "COMPLETE"
          containerName = "tfc-audit-trail-config"
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
      name      = "tfc-audit-trail-config"
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
            endpoint             = var.tfc-audit-trail-url
            scrape_interval_secs = var.scrape-interval-secs
            token                = var.TFC_ORG_TOKEN
            group_name           = aws_cloudwatch_log_group.tfc-audit-trail.name
            region               = var.region
            stream_name          = aws_cloudwatch_log_stream.tfc-audit-trail.name
            page_size            = var.page-size
            cache_num_events     = var.deduplication-cache-size
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
  name            = "tfc-audit-trail-service"
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
