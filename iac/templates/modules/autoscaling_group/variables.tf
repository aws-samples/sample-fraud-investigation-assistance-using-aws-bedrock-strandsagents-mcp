// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0


variable "ami_id" {
  description = "AMI of the EC2 instance. Optional, pulls latest linux AMI by default."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Type of the instance"
  type        = string
  default     = "t3.micro"
}

variable "asg_security_groups" {
  description = "List of security group id(s) to which autoscaling group should be attached"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "User data of the instance"
  type        = string
  default     = ""
}

variable "vpc" {
  description = "VPC of the autoscaling group."
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids"
}