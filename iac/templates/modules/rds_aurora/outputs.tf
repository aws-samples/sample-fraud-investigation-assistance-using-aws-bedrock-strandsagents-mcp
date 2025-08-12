// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "cluster_arn" {
  value       = aws_rds_cluster.aurora.arn
  description = "ARN of the rds cluster"
}

output "cluster_identifier" {
  value       = aws_rds_cluster.aurora.id
  description = "Cluster identifier of the rds cluster"
}

output "cluster_resource" {
  value       = aws_rds_cluster.aurora.cluster_resource_id
  description = "Cluster resource id of the rds cluster"
}

output "cluster_instances" {
  value       = aws_rds_cluster.aurora.cluster_members
  description = "List of instances that are part of the rds cluster"
}

output "instance_id" {
  value       = aws_rds_cluster_instance.cluster_instances[*].id
  description = "ID of the rds instances"
}

output "endpoint" {
  value       = aws_rds_cluster.aurora.endpoint
  description = "Endpoint of the rds cluster"
}

output "database_name" {
  value       = aws_rds_cluster.aurora.database_name
  description = "Name of the RDS DB"
}