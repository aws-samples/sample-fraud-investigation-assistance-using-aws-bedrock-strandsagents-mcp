// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

resource "aws_lambda_layer_version" "psycopg2_lambda_layer" {
  layer_name          = "${local.id}-psycopg2-layer"
  filename            = "${var.appPath}/layers/psycopg2/layer.zip"
  description         = "psycopg2 layer for RDS"
  skip_destroy        = false
  compatible_runtimes = ["python3.9", "python3.10", "python3.11", "python3.12", "python3.13"]
}

resource "aws_lambda_layer_version" "strands_agent_lambda_layer" {
  layer_name          = "${local.id}-strands-agent-layer"
  filename            = "${var.appPath}/layers/strands-agents/layer.zip"
  description         = "strands layer for mcp agents"
  skip_destroy        = false
  compatible_runtimes = ["python3.9", "python3.10", "python3.11", "python3.12", "python3.13"]
}