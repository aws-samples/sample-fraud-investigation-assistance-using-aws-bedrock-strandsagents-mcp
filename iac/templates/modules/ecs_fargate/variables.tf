// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "id" {
  description = "Description of the variable"
  type        = string
}

variable "vpc_id" {
  description = "ID of VPC to deploy ECS Fargate"
  type        = string
}

variable "image_url" {
  description = "Description of the variable"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of IAM role that the task will assume to interact with other services"
  type        = string
}

variable "execution_policies" {
  description = "Other policies to add to the execution role other than AmazonECSTaskExecutionRolePolicy"
  type = list(string)
  default = []
}

variable "subnet_ids" {
  type = list(string)
}

variable "assign_public_ip" {
  type = bool
  default = false
}

variable "alb_target_group_arn" {
  type = string
}

variable "alb_target_group_port" {
  type = number
}

variable "sg_id" {
  type = string
}

variable "health_check" {
  type = string
  default = "curl -f http://localhost:8080/ >> /proc/1/fd/1 2>&1 || exit 1"
}

variable "desired_count" {
  type = number
  default = 1
}

variable "environment_variables" {
  type = map(string)
  default = {}
}

variable "secrets_variables" {
  type = map(string)
  default = {}
}