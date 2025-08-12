// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

module "strands_agent" {
  source = "../../templates/components/mcp_client"

  id    = "${local.id}-strands"
  tags  = local.tags

  code_path = "${var.appPath}/lambdas/packages/strands-agent-mcp.zip"
  layer_arns = [
    aws_lambda_layer_version.strands_agent_lambda_layer.arn
    ]

  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = var.vpc_cidr_block 
  subnet_ids = module.vpc.vpc_private_subnet_ids
  security_group_ids = [aws_security_group.strands_mcp_sg.id]

  resource_policy_arns = [aws_iam_policy.bedrock_model_access_policy.arn]

  environment_variables = {
    MERCH_ALB_DNS  = module.merchant_mcp.alb_dns_name
    TRANS_ALB_DNS  = module.transaction_mcp.alb_dns_name
    SEARCH_ALB_DNS  = module.brave_mcp.alb_dns_name
    FETCH_ALB_DNS = module.fetch_mcp.alb_dns_name
    MCP_PATH = "/mcp"
    AGENT_MODEL = "us.amazon.nova-pro-v1:0"
  }
}

resource "aws_lambda_permission" "allow_bedrock_strands_agent_access" {
  depends_on    = [
    aws_bedrockagent_agent.fraud_investigator_assistant,
    module.strands_agent
  ]
  statement_id  = "AllowExecutionFromBedrockAgent"
  action        = "lambda:InvokeFunction"
  function_name = module.strands_agent.lambda_function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = aws_bedrockagent_agent.fraud_investigator_assistant.agent_arn
}