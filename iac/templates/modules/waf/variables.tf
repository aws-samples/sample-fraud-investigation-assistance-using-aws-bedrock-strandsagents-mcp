// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Module's input variables
#
variable "name" {
  description = "Name of the ACL"
  type        = string
}

variable "waf_whitelist_ips" {
  description = "List of allowed IP ranges"
  type        = list(string)
  default     = null
}

variable "scope" {
  description = "Scope of the IP set, can be either REGIONAL or CLOUDFRONT"
  type        = string
  default     = "CLOUDFRONT"
}

variable "description" {
  description = "Description of the ACL"
  type        = string
  default     = null
}