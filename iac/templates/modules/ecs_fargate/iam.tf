// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_iam_role" "main" {
  name = "${var.id}-ecs-task-execution-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "main" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.main.name
}

output "test_set" {
  value = toset(var.execution_policies)
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  count = length(var.execution_policies)

  role       = aws_iam_role.main.name
  policy_arn = var.execution_policies[count.index]
}
