// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.id}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the CloudWatch policy to the role
resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${local.id}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${local.id}:*",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/${local.id}",
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })
}


resource "aws_iam_role" "ecs_task_role" {
  name = "${local.id}-ecs-task-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# Policy to allow access to all secrets
resource "aws_iam_policy" "secrets_access_policy" {
  name = "${local.id}-secrets-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]  # You might want to restrict this to specific KMS keys
      }
    ]
  })
}

resource "aws_iam_role" "agent_role" {
  name = "${local.id}-agent-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "bedrock_model_access_policy" {
  name        = "${local.id}-bedrock-model-access-policy"
  description = "Policy to allow invoking Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*",
          "arn:aws:bedrock:*::foundation-model/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "bedrock_kb_access_policy" {
  name        = "${local.id}-bedrock-kb-access-policy"
  description = "Policy to allow invoking Bedrock knowledge bases"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:ListAgentKnowledgeBases",
          "bedrock:GetAgentKnowledgeBase",
          "bedrock:GetKnowledgeBase",
          "bedrock:ListKnowledgeBases",
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate",
          "bedrock:GetKnowledgeBase",
          "bedrock:GetKnowledgeBaseDocuments"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*",
          "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent-alias/*",
          "arn:aws:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
        ]
      }
    ]
  })
}

output "test_lambda_arn" {
  value = module.strands_agent.lambda_function_arn
}

resource "aws_iam_policy" "lambda_access_policy" {
  name        = "${local.id}-lambda-access-policy"
  description = "Policy to allow invoking lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect = "Allow"
        Resource = [
          module.strands_agent.lambda_function_arn,
          "${module.strands_agent.lambda_function_arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent-bedrock-model-attachment" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.bedrock_model_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "agent-bedrock-kb-attachment" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.bedrock_kb_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "agent-lambda-attachment" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.lambda_access_policy.arn
}


resource "aws_iam_policy" "db_data_s3_policy" {
  name        = "${local.id}-db-data-s3-policy"
  description = "IAM policy for Lambda to access DB data in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_db_data.arn,
          "${module.s3_db_data.arn}/*"
        ]
      }
    ]
  })
}