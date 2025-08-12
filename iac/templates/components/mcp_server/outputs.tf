// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

output "alb_dns_name" {
  value       = module.alb.dns_name
  description = "DNS name of the ALB"
}

output "execution_policies" {
  value = module.service.execution_policies
}