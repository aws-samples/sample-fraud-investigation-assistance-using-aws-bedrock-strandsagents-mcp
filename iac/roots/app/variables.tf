// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

variable "appName" {
  type = string
}

variable "envName" {
  type = string
}

variable "brave_api_key" {
  type = string
}

variable "appPath" {
  type = string
  description = "Path to application level code"
  default = "../../../app"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of public subnet CIDR blocks for each AZ"
  default     = ["10.0.0.0/18", "10.0.64.0/18"]
}

variable "private_subnets_cidr_blocks" {
  type        = list(string)
  description = "List of public subnet CIDR blocks for each AZ"
  default     = ["10.0.128.0/18", "10.0.192.0/18"]
}

variable "agent_model_id" {
  type        = string
  description = "Model id for agent orchestration"
  default     = "amazon.nova-lite-v1:0"
}

variable "dataPath" {
  type = string
  description = "Path to data level code"
  default = "../../../data"
}