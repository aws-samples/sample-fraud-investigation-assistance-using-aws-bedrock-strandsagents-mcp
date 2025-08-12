// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "alb_dns" {
  description = "DNS of the load balancer"
  value       = aws_alb.load_balancer.dns_name
}

output "iam_arn" {
  description = "ARN of ASG EC2 IAM role"
  value       = aws_iam_role.asg_iam_role.arn
}
