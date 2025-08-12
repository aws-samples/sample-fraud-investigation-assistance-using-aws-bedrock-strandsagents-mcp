// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# ALB
# Not enforcing deletion protection to allow for deploy and destroy easily
# ELB access logs not enabled because ELB root account would have to have access to keys
# nosemgrep: missing-aws-lb-deletion-protection, aws-elb-access-logs-not-enabled
resource "aws_alb" "main" {
  #checkov:skip=CKV_AWS_150: "Not enforcing deletion protection to allow for deploy and destroy easily"
  name            = "${var.id}-alb"
  internal        = var.internal_lb
  load_balancer_type = "application"
  security_groups = [var.security_group_id]
  subnets         = var.subnet_ids
  drop_invalid_header_fields = true
  dynamic "access_logs" {
    for_each = var.access_log_bucket != null ? [1] : []
    content {
      bucket  = var.access_log_bucket
      prefix  = "${var.id}-alb-logs"
      enabled = true
    }
  }
}

# Target Group
resource "aws_alb_target_group" "main" {
  name        = "${var.id}-alb-tg"
  port        = var.outgoing_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    path                = var.health_check
    port                = 8080
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 300
    matcher             = "200"   # TODO: wrap MCP Server with a lambda that create a proper health check with session header curl -X GET http://127.0.0.1:8080/mcp/health -H "Accept: text/event-stream" ALB health not supporting custom header
  }
}


# Listener
# nosemgrep: insecure-load-balancer-tls-version, aws-cloudwatch-log-group-unencrypted # ALB protocol does not need to be HTTPS for prototype
resource "aws_alb_listener" "main" {
  #checkov:skip=CKV_AWS_2: "ALB protocol does not need to be HTTPS for prototype"
  #checkov:skip=CKV_AWS_103: "ALB using HTTP and therefore does not need at least TLS 1.2"
  load_balancer_arn = aws_alb.main.arn
  port              = var.incoming_listener_port
  protocol          = "HTTP" # nosemgrep: insecure-load-balancer-tls-version
  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type             = "forward"
  }
}
