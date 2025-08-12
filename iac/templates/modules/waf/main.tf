// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  managed_rule_sets = ["AWSManagedRulesCommonRuleSet", "AWSManagedRulesKnownBadInputsRuleSet", "AWSManagedRulesSQLiRuleSet"]
}

#
# IP set
#
resource "aws_wafv2_ip_set" "ipset" {

  lifecycle {
    create_before_destroy = true
  }
  count              = var.waf_whitelist_ips != null ? 1 : 0
  name               = "WAFWhitelistIPs"
  description        = "Whitelist of specific IP range"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.waf_whitelist_ips
}

#
# WEB ACL
#
resource "aws_wafv2_web_acl" "acl" {
  #Skipping checkov checks
  #checkov:skip=CKV_AWS_192: "Ensure WAF prevents message lookup in Log4j2. See CVE-2021-44228 aka log4jshell" <- False posititve
  lifecycle {
    create_before_destroy = true
  }

  name        = var.name
  description = var.description
  scope       = var.scope

  default_action {
    allow {}
  }

  # Managed rules
  dynamic "rule" {
    for_each = { for i, k in local.managed_rule_sets : i => k }
    iterator = r
    content {
      name     = "AWS-${r.value}"
      priority = r.key
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = r.value
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-${r.value}"
        sampled_requests_enabled   = true
      }
    }
  }

  #
  # Block any IP outside of the IP set
  #
  dynamic "rule" {
    for_each = var.waf_whitelist_ips != null ? [1] : []
    content {

      name     = "WAFWhitelistIPs-CLOUDFRONT"
      priority = length(local.managed_rule_sets)

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            ip_set_reference_statement {
              arn = aws_wafv2_ip_set.ipset[0].arn
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-WHITELISTIps-CLOUDFRONT"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-WAF-CLOUDFRONT"
    sampled_requests_enabled   = true
  }
}

#
# Log group
#
module "logs" {
  source = "../cloudwatch_log_group"
  # Name needs to follow WAF imposed convention and start with "aws-waf-logs"
  name     = lower("aws-waf-logs-${var.name}")
  services = ["logs.amazonaws.com"]
}

#
# Log configuration
#
resource "aws_wafv2_web_acl_logging_configuration" "logging" {
  log_destination_configs = [module.logs.arn]
  resource_arn            = aws_wafv2_web_acl.acl.arn
}