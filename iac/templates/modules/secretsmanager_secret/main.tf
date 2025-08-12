// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Secret
#
resource "aws_secretsmanager_secret" "secret" {
  # name_prefix             = var.name_prefix
  name                    = var.name
  kms_key_id              = var.kms_id
  recovery_window_in_days = 0     # Force delete
  tags                    = var.tags
}

#
# Secret version
#
resource "aws_secretsmanager_secret_version" "version" {
  count = (length(var.secret_values) > 0 || length(var.secret_single_value) > 0) ? 1 : 0

  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = length(var.secret_values) > 0 ? jsonencode(var.secret_values) : var.secret_single_value
}
#
# Secret rotation
#
resource "aws_secretsmanager_secret_rotation" "rotation" {
  count = var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.secret.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_interval
  }
}