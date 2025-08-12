// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

variable "id" {
  type        = string
  description = "Identifier for the MCP client resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for Lambda function"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for Lambda function"
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the lambda function"
}

variable "mcp_server_port" {
  type        = number
  default     = 80
  description = "Port number for MCP server"
}

variable "appPath" {
  type = string
  description = "Path to application level code"
  default = "../../../app"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block of the VPC"
}

variable "code_path" {
  type        = string
  description = "Path to the zip file of the packaged code"
}

variable "layer_arns" {
  type        = list(string)
  description = "List of arns for lambda layer"
}

variable "resource_policy_arns" {
  type    = list(string)
  default = []
}