// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

# Lambda function for database deployment
module "deploy_db_function" {
  source        = "../../templates/modules/lambda"

  function_name = "${local.id}-deploy-db"
  handler_name  = "handler.lambda_handler"
  description   = "Deploy DDL and DML scripts to PostgresDB"
  resource_policies = [
    aws_iam_policy.secrets_kms_policy.arn,
    aws_iam_policy.lambda_vpc_policy.arn,
    aws_iam_policy.db_data_s3_policy.arn
  ]
  runtime       = "python3.13"
  code_archive  = "${path.module}/${var.appPath}/lambdas/packages/deploy-db.zip"
  layer_arns    = [aws_lambda_layer_version.psycopg2_lambda_layer.arn]

  subnet_ids         = module.vpc.vpc_private_subnet_ids
  security_group_ids = [aws_security_group.db_lambda_sg.id]

  environment_variables = {
    DB_SECRET_NAME = "${local.id_path}/db-secret"
    S3_BUCKET      = module.s3_db_data.name
  }
}


module "query_data_function" {
  source            = "../../templates/modules/lambda"

  function_name     = "${local.id}-query-data"
  handler_name      = "handler.lambda_handler"
  description       = "Query transactions and merchants from PostgresDB"
  resource_policies = [
    aws_iam_policy.secrets_kms_policy.arn,
    aws_iam_policy.lambda_vpc_policy.arn
  ]
  runtime           = "python3.13"
  code_archive      = "${path.module}/${var.appPath}/lambdas/packages/query-data.zip"
  layer_arns        = [aws_lambda_layer_version.psycopg2_lambda_layer.arn]

  subnet_ids         = module.vpc.vpc_private_subnet_ids
  security_group_ids = [aws_security_group.db_lambda_sg.id]

  environment_variables = {
    DB_SECRET_NAME = "${local.id_path}/db-secret"
  }
}


resource "aws_iam_policy" "lambda_vpc_policy" {
  #checkov:skip=CKV_AWS_290: "Lambda requires these permissions to work with VPC and these actions can only be applied to network interfaces"
  #checkov:skip=CKV_AWS_355: "Lambda requires these permissions to work with VPC and these actions can only be applied to network interfaces"
  name = "${local.id}-lambda-vpc-policy"
  description = "IAM policy for Lambda VPC execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_kms_policy" {
  name = "${local.id}-secrets-kms-query-policy"
  description = "Policy for secret manager and kms"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.db_secret.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          module.kms.arn
        ]
      }
    ]
  })
}

resource "aws_lambda_permission" "lambda_permission_merchant" {
  statement_id  = "AllowAPIInvokeMerchant"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${module.data_api.execution_arn}/*/GET/api/merchant"
}

resource "aws_lambda_permission" "lambda_permission_merchant_stats" {
  statement_id  = "AllowAPIInvokeMerchantStats"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/merchant/stats"
}

resource "aws_lambda_permission" "lambda_permission_merchant_details" {
  statement_id  = "AllowAPIInvokeMerchantDetails"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/merchant/details"
}

resource "aws_lambda_permission" "lambda_permission_merchant_search" {
  statement_id  = "AllowAPIInvokeMerchantSearch"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/merchant/search"
}

resource "aws_lambda_permission" "lambda_permission_merchant_filter_stats" {
  statement_id  = "AllowAPIInvokeMerchantFilterStats"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/merchant/filter-stats"
}

resource "aws_lambda_permission" "lambda_permission_merchant_filter_data" {
  statement_id  = "AllowAPIInvokeMerchantFilterData"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/merchant/filter-data"
}

resource "aws_lambda_permission" "lambda_permission_transactions" {
  statement_id  = "AllowAPIInvokeTransactions"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/transaction"
}

resource "aws_lambda_permission" "lambda_permission_transaction_auth" {
  statement_id  = "AllowAPIInvokeTransactionAuthorization"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/transaction/authorization"
}

resource "aws_lambda_permission" "lambda_permission_transaction_settlement" {
  statement_id  = "AllowAPIInvokeTransactionSettlement"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/transaction/settlement"
}

resource "aws_lambda_permission" "lambda_permission_transaction_filter" {
  statement_id  = "AllowAPIInvokeTransactionFilter"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/transaction/filter"
}

resource "aws_lambda_permission" "lambda_permission_transaction_merchant_transactions" {
  statement_id  = "AllowAPIInvokeTransactionMerchantTransactions"
  action        = "lambda:InvokeFunction"
  function_name = module.query_data_function.name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  source_arn = "${module.data_api.execution_arn}/*/GET/api/transaction/merchant-transactions"
}