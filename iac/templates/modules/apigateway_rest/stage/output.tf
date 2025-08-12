// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "endpoint_url" {
  value       = aws_api_gateway_stage.stage.invoke_url
  description = "API endpoint URL"
}

output "endpoint_hostname" {
  value       = trimsuffix(trimprefix(aws_api_gateway_stage.stage.invoke_url, "https://"), "/${var.stage_name}")
  description = "API endpoint URL"
}

output "endpoint_path" {
  depends_on  = [aws_api_gateway_stage.stage]
  value       = "/${var.stage_name}"
  description = "Path of the stage"
}