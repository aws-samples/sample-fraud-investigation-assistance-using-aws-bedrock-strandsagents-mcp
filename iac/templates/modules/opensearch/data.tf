// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Use data sources to get common information about the environment
data "aws_caller_identity" "this" {}
data "aws_partition" "this" {}
data "aws_region" "this" {}