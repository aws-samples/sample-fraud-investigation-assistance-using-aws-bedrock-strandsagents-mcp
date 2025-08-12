// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ECR Repository for container images
# nosemgrep: aws-ecr-mutable-image-tags  # Allow ECR Image Tags to be mutable to update 'latest' image
resource "aws_ecr_repository" "main" {
  #checkov:skip=CKV_AWS_51: "Allow ECR Image Tags to be mutable to update 'latest' image"
  name                 = "${var.id}-ecr-${random_string.main.id}"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = var.tags
}

# Randomizer to make resource creation idempotent
# ECR::CreateRepository is very picky about names
resource "random_string" "main" {
  length   = 8
  special  = false
  numeric = true
  min_numeric = 8
  upper    = false
}

resource "aws_kms_key" "main" {
  description              = "KMS key for ECR images"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  tags                     = var.tags
}

resource "null_resource" "push_image" {
  triggers = {
    repository_url = aws_ecr_repository.main.repository_url
    dockerfile_trigger = filemd5("${var.container_path}/Dockerfile")
    file_trigger = try(filemd5("${var.container_path}/${var.file_trigger}"), "")
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${data.aws_region.current.name} | podman login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      podman build --platform ${var.platform} -t ${aws_ecr_repository.main.repository_url}:latest ${var.container_path}
      podman push ${aws_ecr_repository.main.repository_url}:latest
    EOT
  }

  depends_on = [
    aws_ecr_repository.main
  ]
}