// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Create outputs here
#
output "arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.secret.arn
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.secret.id
}

