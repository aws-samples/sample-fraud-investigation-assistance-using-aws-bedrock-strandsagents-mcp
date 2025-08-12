// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

#
# Module's input variables
#
variable "id" {
  description = "Description of the variable"
  type        = string
}

variable "vpc_id" {
  description = "Description of the variable"
  type        = string
}

variable "alb_subnet_ids" {
  description = "Description of the variable"
  type        = list(string)
}

variable "ecs_subnet_ids" {
  description = "Description of the variable"
  type        = list(string)
}

variable "health_check" {
  type = string
}

variable "alb_health_check" {
  type = string
}


variable "alb_sg_id" {
  description = "Description of the variable"
  type        = string
}

variable "ecs_sg_id" {
  description = "Description of the variable"
  type        = string
}

variable "container_path" {
  description = "Description of the variable"
  type        = string
}

variable "file_trigger" {
  description = "Description of the variable"
  type        = string
}


variable "ecs_task_role_arn" {
  description = "Description of the variable"
  type        = string
}

variable "ecs_execution_policies" {
  description = "Other policies to add to the execution role other than AmazonECSTaskExecutionRolePolicy"
  type = list(string)
  default = []
}

variable "tags" {
  type = map(string)
}

variable "environment_variables" {
  type = map(string)
  default = {}
}

variable "secrets_variables" {
  type = map(string)
  default = {}
}

variable "access_log_bucket" {
  description = "The S3 bucket name to store ALB access logs"
  type        = string
  default     = null
}