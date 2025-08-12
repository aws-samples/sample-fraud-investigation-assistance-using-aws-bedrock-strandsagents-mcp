// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_region" "current" {}

# Define the task definition
resource "aws_ecs_task_definition" "main" {
  #checkov:skip=CKV_AWS_336: ECS containers need to write to root filesystems for opensource MCPs
  family                   = "${var.id}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.main.arn
  task_role_arn            = var.task_role_arn
  container_definitions    = jsonencode(
[
  {
    "name": "${var.id}-cluster",
    "image": "${var.image_url}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      },
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "secrets" : [
      for name, value in var.secrets_variables : {
        "name"  = name
        "valueFrom" = value
      }
    ]
    "environment": concat([
      {
        "name": "LOG_GROUP_NAME",
        "value": "/fargate/service/${var.id}"
      },
      {
        "name": "LOG_STREAM_NAME",
        "value": "ecs"
      }
    ],
    [
      for name, value in var.environment_variables : {
        "name"  = name
        "value" = value
      }
    ])
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/${var.id}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "healthCheck": {
      "command": ["CMD-SHELL", "${var.health_check}"],
      "interval": 300,
      "timeout": 10,
      "retries": 3,
      "startPeriod": 120
    }
  }
])
}

# Create the ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.id}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Create the ECS Fargate service
resource "aws_ecs_service" "main" {
  name            = "${var.id}-cluster"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  platform_version = "LATEST"
  health_check_grace_period_seconds = 120

  network_configuration {
    security_groups  = [var.sg_id]
    subnets         = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.id}-cluster"
    container_port   = var.alb_target_group_port
  }

  depends_on = [aws_ecs_task_definition.main]
}

# nosemgrep: missing-cloudwatch-log-group-kms-key, aws-cloudwatch-log-group-unencrypted   # CloudWatch log group encryption not required
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.id}"
  retention_in_days = 90
}