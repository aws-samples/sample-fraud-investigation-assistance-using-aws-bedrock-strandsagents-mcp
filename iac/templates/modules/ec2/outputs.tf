// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

#
# Create outputs here
#
output "arn" {
  description = "ARN of the instance"
  value       = aws_instance.ec2.arn
}

output "private_dns" {
  description = "Private DNS of the instance"
  value       = aws_instance.ec2.private_dns
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.ec2.public_ip
}

output "public_dns" {
  description = "Public DNS of the instance"
  value       = aws_instance.ec2.public_dns
}

output "iam_arn" {
  description = "ARN of EC2 IAM role"
  value       = aws_iam_role.ec2_iam_role.arn
}