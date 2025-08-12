// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


locals {
  stages = ["prod", "test"]
}

#
# API Gateway API
#
resource "aws_api_gateway_rest_api" "api" {
  body = var.api_spec
  name = var.api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

#
# Standard WAF ACL
#
module "waf-api" {
  source = "../waf"
  name   = var.api_name
  scope  = "REGIONAL"
}

#
# Stage(s)
#
module "stage" {
  depends_on = [aws_api_gateway_rest_api.api]
  for_each           = toset(local.stages)
  source             = "./stage"
  api_id             = aws_api_gateway_rest_api.api.id
  stage_name         = each.key
  deployment_trigger = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  waf_acl_arn        = module.waf-api.arn
}






