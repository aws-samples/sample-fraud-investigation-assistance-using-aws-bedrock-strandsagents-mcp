// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  # Accounts for Access logs for Application Load Balancers, region for Ireland
  # Full list -> https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
  account_map = {
    "us-east-1"       = "127311923021",
    "us-east-2"       = "033677994240",
    "us-west-1"       = "027434742980",
    "us-west-2"       = "797873946194",
    "af-south-1"      = "098369216593",
    "ap-east-1"       = "754344448648",
    "ap-southeast-3"  = "589379963580",
    "ap-south-1"      = "718504428378",
    "ap-noprtheast-3" = "383597477331",
    "ap-northeast-2"  = "600734575887",
    "ap-southeast-1"  = "114774131450",
    "ap-southeast-2"  = "783225319266",
    "ap-northeast-1"  = "582318560864",
    "ca-central-1"    = "985666609251",
    "eu-central-1"    = "054676820928",
    "eu-west-1"       = "156460612806",
    "eu-west-2"       = "652711504416",
    "eu-south-1"      = "635631232127",
    "eu-west-3"       = "009996457667",
    "eu-north-1"      = "897822967062",
    "me-south-1"      = "076674570225",
    "sa-east-1"       = "507241528517"
  }
  alb_root_account_id = lookup(local.account_map, data.aws_region.current.name)
}

data "aws_region" "current" {}

#
# Log bucket 
#
data "aws_iam_policy_document" "access_policy" {
  statement {
    sid    = "AllowELBRootAccount"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.alb_root_account_id}:root"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${module.lb_access_logs_bucket.name}/*"]
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${module.lb_access_logs_bucket.name}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${module.lb_access_logs_bucket.name}"]
  }
}

module "lb_access_logs_bucket" {
  source        = "./../s3_bucket"
  name_prefix   = "lbaccesslogs"
  access_policy = data.aws_iam_policy_document.access_policy.json

}


# nosemgrep: missing-aws-lb-deletion-protection # Not enforcing deletion protection to allow for deploy and destroy easily
resource "aws_alb" "load_balancer" {
  #checkov:skip=CKV_AWS_150: "Ensure that Load Balancer has deletion protection enabled"
  name               = "load-balancer"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields = true
  access_logs {
    bucket  = module.lb_access_logs_bucket.name
    enabled = true
  }
}

resource "aws_lb_target_group" "target_group" {
  #checkov:skip=CKV_AWS_261: "Ensure HTTP HTTPS Target group defines Healthcheck"
  #checkov:skip=CKV_AWS_378: "Ensure AWS Load Balancer doesn't use HTTP protocol"
  name     = "lb-target-group"
  port     = "8080"
  protocol = "HTTP"
  vpc_id   = var.vpc
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
    # target_group_arn = aws_lb_target_group.target_group.arn
  }
}

data "aws_iam_policy_document" "asg_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "asg_iam_role" {
  name_prefix        = "asg-role-"
  assume_role_policy = data.aws_iam_policy_document.asg_role_policy.json
}

data "aws_iam_policy" "ssm" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.asg_iam_role.name
  policy_arn = data.aws_iam_policy.ssm.arn
}

resource "aws_placement_group" "asg_placement_group" {
  name         = "sample_placement_group"
  strategy     = "spread" # "cluster" "partition"
  spread_level = "rack"
}

resource "aws_autoscaling_group" "asg" {
  name     = "sample-asg"
  min_size = 2
  max_size = 5

  placement_group = aws_placement_group.asg_placement_group.id

  launch_template {
    id      = aws_launch_template.sample_launch_template.id
    version = aws_launch_template.sample_launch_template.latest_version
  }

  vpc_zone_identifier = var.subnet_ids

  tag {
    key                 = "Name"
    value               = "terraform-reusable-assets-ASG"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "sample_launch_template" {
  name_prefix            = "lt-"
  image_id               = var.ami_id != null ? var.ami_id : data.aws_ami.default_amazon_linux_ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.asg_security_groups
  user_data              = base64encode(var.user_data)

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

}

data "aws_ami" "default_amazon_linux_ami" {
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
