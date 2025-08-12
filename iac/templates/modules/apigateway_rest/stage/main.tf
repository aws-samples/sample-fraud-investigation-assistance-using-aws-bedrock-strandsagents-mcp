// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#
# Deployment of the API
#
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = var.api_id

  triggers = {
    redeployment = var.deployment_trigger
  }

  lifecycle {
    create_before_destroy = true
  }

  variables = {
    lambdaAlias = var.stage_name
  }
}


module "access_logs" {
  source   = "../../cloudwatch_log_group"
  name     = "/api/${var.api_id}/${var.stage_name}"
  services = ["logs.${data.aws_region.current.name}.amazonaws.com"]
}

#
# Stage
#
# nosemgrep: missing-api-gateway-cache-cluster # Caching not required for prototype
resource "aws_api_gateway_stage" "stage" {
  #Skipping checkov checks
  #checkov:skip=CKV_AWS_120: "Ensure API Gateway caching is enabled"
  #checkov:skip=CKV2_AWS_51: "Ensure AWS API Gateway endpoints uses client certificate authentication"
  deployment_id        = aws_api_gateway_deployment.deployment.id
  rest_api_id          = var.api_id
  stage_name           = var.stage_name
  xray_tracing_enabled = true
  access_log_settings {
    destination_arn = module.access_logs.arn
    format = jsonencode(
      {
        requestid         = "$context.requestId"
        extendedRequestId = "$context.extendedRequestId"
        ip                = "$context.identity.sourceIp"
        caller            = "$context.identity.caller"
        user              = "$context.identity.user"
        requestTime       = "$context.requestTime"
        httpMethod        = "$context.httpMethod",
        resourcePath      = "$context.resourcePath"
        status            = "$context.status"
        protocol          = "$context.protocol"
        responseLength    = "$context.responseLength"
      }
    )
  }

  variables = {
    lambdaAlias = var.stage_name
  }
}

#
# Enable logging at error level
#
resource "aws_api_gateway_method_settings" "prod" {
  #checkov:skip=CKV_AWS_225: "Ensure API Gateway method setting caching is enabled"
  rest_api_id = var.api_id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled      = true
    caching_enabled      = false
    cache_data_encrypted = true
    logging_level        = "INFO"
  }
}

resource "aws_wafv2_web_acl_association" "prod_stage" {
  resource_arn = aws_api_gateway_stage.stage.arn
  web_acl_arn  = var.waf_acl_arn
}





