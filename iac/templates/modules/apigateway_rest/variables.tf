// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "api_name" {
  type        = string
  description = "Name of the API"
}

variable "api_spec" {
  type        = string
  description = "OPEN API Specification of the API"
}

variable "user_pool_arn" {
  type        = string
  default     = null
  description = "Cognito user pool ARN"
}

variable "api_domain_name" {
  type        = string
  description = "API custom domain name"
  default     = null
}

variable "r53_zone_id" {
  type        = string
  description = "R53 zone id"
  default     = null
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the certificate to be used"
  default     = null
}