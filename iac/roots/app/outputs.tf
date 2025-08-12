// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

output "region" {
  value       = data.aws_region.current.name
  description = "Deployment region"
}

output "agent_id" {
  depends_on  = [aws_bedrockagent_agent.fraud_investigator_assistant]
  value       = aws_bedrockagent_agent.fraud_investigator_assistant.agent_id
  description = "ID of the Bedrock agent"
}

output "agent_version" {
  depends_on  = [aws_bedrockagent_agent.fraud_investigator_assistant]
  value       = aws_bedrockagent_agent.fraud_investigator_assistant.agent_version
  description = "Version of the Bedrock agent"
}

output "agent_alias_id" {
  depends_on  = [aws_bedrockagent_agent_alias.fraud_investigator_assistant_alias]
  value       = aws_bedrockagent_agent_alias.fraud_investigator_assistant_alias.agent_alias_id
  description = "ID of the Bedrock agent alias"
}

output "strands_agent_function_name" {
  depends_on  = [module.strands_agent]
  value       = module.strands_agent.lambda_function_name
  description = "Name of the strands agent function"
}

output "api_key_secret_arn" {
  value       = aws_secretsmanager_secret.api_key.arn
  description = "ARN of the API key secret"
}