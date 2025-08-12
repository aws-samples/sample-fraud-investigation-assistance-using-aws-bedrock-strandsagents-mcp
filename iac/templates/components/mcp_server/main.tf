// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

module "alb" {
  #checkov:skip=CKV_AWS_378: "ALB using HTTP is sufficient for prototype"
  #checkov:skip=CKV2_AWS_20: "ALB does not need to redirect HTTP to HTTPS for prototype"
  source = "../../modules/alb"

  id = var.id
  vpc_id = var.vpc_id
  subnet_ids = var.alb_subnet_ids
  internal_lb = true
  health_check = var.alb_health_check
  target_type = "ip"
  incoming_listener_port = 80
  outgoing_target_port = 8080
  security_group_id = var.alb_sg_id
  access_log_bucket = var.access_log_bucket
}

module "ecr" {
  #checkov:skip=CKV2_AWS_64: "KMS key policy for ECR is not required for prototype"
  source = "../../modules/ecr"

  id = var.id
  container_path = var.container_path
  file_trigger = var.file_trigger
  tags = var.tags
}

data "aws_ecr_image" "latest" {
  depends_on = [module.ecr]
  repository_name = module.ecr.repository_name
  image_tag       = "latest"
}


module "service" {
  #checkov:skip=CKV_AWS_338: "CloudWatch log groups retaining for 90 days is sufficient for prototype"
  #checkov:skip=CKV_AWS_158: "CloudWatch Log Group encryption by KMS not required for prototype"
  source                = "../../modules/ecs_fargate"

  id                    = "${var.id}-mcp"
  vpc_id                = var.vpc_id
  image_url             = "${module.ecr.repository_url}@${data.aws_ecr_image.latest.image_digest}"
  task_role_arn         = var.ecs_task_role_arn
  execution_policies    = var.ecs_execution_policies
  subnet_ids            = var.ecs_subnet_ids
  assign_public_ip      = false
  alb_target_group_arn  = module.alb.target_group_arn
  alb_target_group_port = 8080
  sg_id                 = var.ecs_sg_id
  desired_count         = 1
  environment_variables = var.environment_variables
  secrets_variables     = var.secrets_variables
  health_check          = var.health_check
}
