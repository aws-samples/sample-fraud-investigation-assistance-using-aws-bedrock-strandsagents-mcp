// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_region" "current" {}

data "aws_iam_policy_document" "ec2_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name_prefix        = "ec2-iam-role-"
  assume_role_policy = data.aws_iam_policy_document.ec2_role_policy.json
}

data "aws_iam_policy" "ssm" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = data.aws_iam_policy.ssm.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instance_profile"
  role = aws_iam_role.ec2_iam_role.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "root_key" {
  source      = "../kms"
  description = "KMS key for the EC2 root block device"
  alias       = "ec2/${var.name}"
}

resource "aws_instance" "ec2" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  associate_public_ip_address = var.public_ip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  key_name                    = var.key_pair_key_name
  source_dest_check           = var.source_dest_check
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  ebs_optimized               = true
  monitoring                  = true
  user_data                   = var.user_data
  tags = {
    Name = "${var.name}"
  }
  root_block_device {
    encrypted  = true
    kms_key_id = module.root_key.arn
  }
  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }
}