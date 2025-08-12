// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "cluster_arn" {
  description = "Description of the output"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_id" {
  description = "Description of the output"
  value       = aws_ecs_cluster.main.id
}

#output "task_private_ips" {
#  value = [for task in data.aws_ecs_task.my_tasks.network_interfaces : task.private_ipv4_address]
#}

output "execution_policies" {
  value = var.execution_policies
}