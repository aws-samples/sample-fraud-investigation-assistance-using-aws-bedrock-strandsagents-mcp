// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_alb_target_group.main.arn
}

output "dns_name" {
  description = "DNS name of the ALB"
  value       = aws_alb.main.dns_name
} 

output "arn" {
  description = "ARN of the ALB"
  value       = aws_alb.main.arn
} 

output "security_group_id" {
  description = "The ID of the security group attached to the ALB"
  value       = var.security_group_id
}