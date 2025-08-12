// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Module's input variables
#

variable "kms_id" {
  description = "The KMS key to encrypt the database"
  type        = string  
}

variable "cluster_identifier" {
  description = "Identifier of the cluster"
  type        = string
  default     = ""
}

variable "cluster_engine" {
  description = "Name of the engine"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = ""
}

variable "master_username" {
  description = "Username of the master account"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet id(s) to which RDS should be attached"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "List of security group id(s) to which RDS should be attached"
}

# Note that the instance class will vary depending on the engine selected.
# Refer to this page to verify the instance class compatibilty :
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.html
variable "instance_class" {
  type        = string
  default     = ""
  description = "Instance type of rds instance"
}

variable "engine_mode" {
  type        = string
  default     = "provisioned"
  description = "Engine mode of the rds instance"
}

variable "enable_http_endpoint" {
  type        = bool
  default     = false
  description = "Enable HTTP endpoint for serverless engine mode"
}

variable "master_password" {
  type        = string
  default     = ""
  description = "Master account password for the rds cluster"
  sensitive   = true
}

variable "backup_kms" {
  type        = string
  default     = ""
  description = "KMS key to encrypt backup vault"
}

variable "port" {
  type        = string
  default     = "5533"
  description = "Port on which to connect to the DB cluster"
}




