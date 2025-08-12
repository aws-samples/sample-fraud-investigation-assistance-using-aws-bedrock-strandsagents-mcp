// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Create outputs here
#
output "arn" {
  description = "ARN of the cloudwatch log group"
  value       = aws_cloudwatch_log_group.log.arn
}

output "name" {
  description = "Name of the cloudwatch log group"
  value       = aws_cloudwatch_log_group.log.name
}