// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
#
# Account setttings to enable logging
#
resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.role.arn
}

#
# Assume role policy
#
data "aws_iam_policy_document" "role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

#
# Role for cloudwatch access
#
resource "aws_iam_role" "role" {
  name_prefix        = "apigateway-cloudwatch-role-"
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

#
# Policy document
#
data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:GetLogEvents",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }
}

#
# Policy allowing acess to cloudwatch
#
resource "aws_iam_role_policy" "cloudwatch" {
  name   = "Cloudwatch_acess"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.policy.json
}