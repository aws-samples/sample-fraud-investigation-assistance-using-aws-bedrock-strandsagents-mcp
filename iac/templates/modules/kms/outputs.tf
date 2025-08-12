// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Create outputs here
#
output "arn" {
  description = "ARN of the KMS key created"
  value       = aws_kms_key.key.arn
}

output "alias" {
  description = "Alias of the KMS key created"
  value       = aws_kms_alias.alias.name
}