// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "repository_arn" {
  description = "ARN of the ECR Repository"
  value       = aws_ecr_repository.main.arn
}

output "repository_url" {
  description = "URL for ECR Repository"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_name" {
  description = "Name of the ECR Repository"
  value       = aws_ecr_repository.main.name
}
