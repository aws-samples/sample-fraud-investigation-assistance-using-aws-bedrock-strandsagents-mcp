// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Cognito authorizer
#
resource "aws_api_gateway_authorizer" "api_authorizer" {
  count         = var.user_pool_arn != null ? 1 : 0
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = [var.user_pool_arn]
}