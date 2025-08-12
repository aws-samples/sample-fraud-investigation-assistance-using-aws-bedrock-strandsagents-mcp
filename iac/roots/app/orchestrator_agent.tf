// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

resource "aws_bedrockagent_agent" "fraud_investigator_assistant" {
  #checkov:skip=CKV_AWS_383: "Bedrock guardrails association not required for prototype"
  #checkov:skip=CKV_AWS_373: "CMK agent encryption not required for prototype"
  agent_name                  = "${local.id}-fraud-investigator"
  agent_resource_role_arn     = aws_iam_role.agent_role.arn
  idle_session_ttl_in_seconds = 600
  foundation_model            = var.agent_model_id
  instruction                 = <<-EOT
    You are a fraud investigator assistant that uses its support agents and investigation procedures to answer questions.

    You have the following resources:
    - A knowledge base of procedures to follow given investigator requests
    - Several support agents that have expertise in certain domains.

    Always consult the knowledge base first, no matter what, before utilizing any support agents to see if there is a clear procedures you should follow to provide the investigator with the right information.
    Even if you do not believe the knowledge base will have helpful information or the right policy, you must always query it first before querying any support agents.
    If there is no relevant procedure, use your best judgement of which support agents to utilize.
    Consider the support agents you have available and send relevant queries to them. They are also agents to word your request carefully and reword if required.
    If there's no clear execution plan or the intent is not clear, respond back with qualifying question or reject the request politely. 

    Note: merchant identifier's are formatted as 'MRCH1234' and transaction identifiers are formmatted as 'XXXXXXXXXXXX1234'.
  EOT
  prepare_agent               = true
  depends_on = [
    aws_iam_role_policy_attachment.agent-bedrock-model-attachment,
    aws_iam_role_policy_attachment.agent-bedrock-kb-attachment,
    aws_iam_role_policy_attachment.agent-lambda-attachment
  ]
}

resource "aws_bedrockagent_agent_action_group" "support_agent_ag" {
  action_group_name          = "support_agent_action_group"
  agent_id                   = aws_bedrockagent_agent.fraud_investigator_assistant.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  prepare_agent              = true
  action_group_executor {
    lambda = module.strands_agent.lambda_function_arn
  }
  api_schema {
    payload = file("${var.appPath}/action-group-schemas/support-agent-action-group.yaml")
  }
}

resource "aws_bedrockagent_agent_alias" "fraud_investigator_assistant_alias" {
  depends_on       = [
    aws_bedrockagent_agent.fraud_investigator_assistant,
    aws_bedrockagent_agent_action_group.support_agent_ag,
    aws_bedrockagent_agent_knowledge_base_association.fraud_investigator_assistant_kb
  ]
  agent_alias_name = "${local.id}-fraud-investigator-alias"
  agent_id         = aws_bedrockagent_agent.fraud_investigator_assistant.agent_id
  description      = "Fraud Investigator Alias"

  lifecycle {
    replace_triggered_by = [
      aws_bedrockagent_agent.fraud_investigator_assistant
    ]
  }
}

resource "aws_bedrockagent_agent_knowledge_base_association" "fraud_investigator_assistant_kb" {
  agent_id             = aws_bedrockagent_agent.fraud_investigator_assistant.agent_id
  description          = "Fraud Investigation Knowledge Base containing policies for merchant search, contact validation, and authorization decline analysis with investigation steps and procedures."
  knowledge_base_id    = aws_bedrockagent_knowledge_base.fraud_kb.id
  knowledge_base_state = "ENABLED"
  agent_version        = aws_bedrockagent_agent.fraud_investigator_assistant.agent_version
}