// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# KMS Key for cloudwatch
#
module "log_key" {
  source       = "../kms"
  alias        = "cloudwatch/${var.name}"
  description  = "KMS key for data encryption of Cloudwatch logs"
  roles        = var.roles
  services     = var.services
  via_services = var.via_services
}

#
# Log group
#
resource "aws_cloudwatch_log_group" "log" {
  name              = var.name
  retention_in_days = var.log_retention_days
  kms_key_id        = module.log_key.arn
}