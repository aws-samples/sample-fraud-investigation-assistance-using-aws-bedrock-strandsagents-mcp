// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

module "lambda" {
  source = "../../modules/lambda"

  function_name     = "${var.id}-mcp-client"
  handler_name      = "handler.lambda_handler"
  description       = "Transaction and Merchant MCP Client talks to MCP Server"
  runtime           = "python3.13"
  timeout           = 60

  code_archive      = var.code_path
  
  layer_arns = var.layer_arns
  
  subnet_ids        = var.subnet_ids
  security_group_ids = var.security_group_ids

  resource_policies = concat(var.resource_policy_arns, [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ])
  environment_variables = var.environment_variables
}