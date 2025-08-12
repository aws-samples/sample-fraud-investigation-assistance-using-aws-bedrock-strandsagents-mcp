// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "rest_api_id" {
  value = resource.aws_api_gateway_rest_api.api.id
}

output "execution_arn" {
  value = resource.aws_api_gateway_rest_api.api.execution_arn
}

output "endpoint_url" {
  value       = module.stage["prod"].endpoint_url
  description = "API endpoint URL"
}

output "endpoint_hostname" {
  value       = module.stage["prod"].endpoint_hostname
  description = "API endpoint URL"
}

output "endpoint_path" {
  value       = module.stage["prod"].endpoint_path
  description = "API endpoint URL"
}