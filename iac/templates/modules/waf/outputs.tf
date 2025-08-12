// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Create outputs here
#
output "arn" {
  description = "Description of the output"
  value       = resource.aws_wafv2_web_acl.acl.arn
}