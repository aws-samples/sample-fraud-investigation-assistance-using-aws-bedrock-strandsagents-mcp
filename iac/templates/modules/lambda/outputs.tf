// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "name" {
  value       = aws_lambda_function.function.function_name
  description = "Name of the lambda function"
}

output "arn" {
  value       = aws_lambda_function.function.arn
  description = "ARN of the lambda function"
}

output "invocation_arn" {
  value       = aws_lambda_function.function.invoke_arn
  description = "Invocation ARN of the lambda function"
}

output "version" {
  value = aws_lambda_function.function.version
  description = "Version of the lambda function"
}
