// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "id" {
  description = "Prefix of the variable and id of the deployment"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_type" {
  type = string
}

variable "incoming_listener_port" {
  type = number
}

variable "health_check" {
  type = string
  default = "/health"
}

variable "outgoing_target_port" {
  type = number
}

variable "internal_lb" {
  type = bool
  description = "Indicator for if the ALB is an internal alb or not (external alb)"
}

variable "security_group_id" {
  type = string
}

variable "access_log_bucket" {
  description = "The S3 bucket name to store ALB access logs"
  type        = string
  default     = null
}
