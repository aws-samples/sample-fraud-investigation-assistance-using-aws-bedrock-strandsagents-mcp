// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

output "lambda_function_name" {
  value = module.lambda.name
}

output "lambda_function_arn" {
  value = module.lambda.arn
}

output "lambda_function_version" {
  value = module.lambda.version
}