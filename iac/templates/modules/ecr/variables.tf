// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "id" {
  type = string
}

variable "container_path" {
  type = string
}

variable "file_trigger" {
  description = "Rebuild container when this file is changed."
  type = string
  default = null
}

variable "tags" {
  type = map(string)
}

variable "platform" {
  type = string
  description = "Platform type, ex: linux/arm64, linux/amd64"
  default = "linux/amd64"
}