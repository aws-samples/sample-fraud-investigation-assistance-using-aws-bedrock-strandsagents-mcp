// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Module's input variables
#
variable "name" {
  description = "Name prefix of the secret"
  type        = string
}

variable "kms_id" {
  description = "KMS key id to encrypt the secret"
  type        = string
}

variable "secret_values" {
  description = "Map of secret key-value pairs"
  type        = map(string)
  default = {}
}

variable "secret_single_value" {
  description = "Secret value"
  type        = string
  default = ""
}

variable "rotation_lambda_arn" {
  description = "ARN of the lambda function to be used to rotate secret"
  type        = string
  default     = null
}

variable "rotation_interval" {
  type        = number
  description = "Secret rotation interval"
  default     = 7
}

variable "tags" {
  description = "Tags to be applied to the secret"
  type        = map(string)
  default     = {}
}


