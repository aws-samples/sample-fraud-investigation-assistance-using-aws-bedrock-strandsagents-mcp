// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.


module "merchant_mcp" {
  source = "../../templates/components/mcp_server"

  id = "${local.id}-merchant"
  tags = local.tags
  container_path = "${var.appPath}/containers/merchant_mcp"
  file_trigger = "handler.py"
  alb_health_check = "/healthz"
  vpc_id = module.vpc.vpc_id
  alb_subnet_ids = module.vpc.vpc_private_subnet_ids
  alb_sg_id = aws_security_group.alb_sg.id
  health_check = "curl -f http://localhost:8080/healthz >> /proc/1/fd/1 2>&1 || exit 1"
  ecs_subnet_ids = module.vpc.vpc_private_subnet_ids
  ecs_sg_id = aws_security_group.ecs_tasks_sg.id
  ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
  ecs_execution_policies = [aws_iam_policy.secrets_access_policy.arn]
  environment_variables = {
    API_GATEWAY_BASE_URL = module.data_api.endpoint_url
  }
  secrets_variables = {
    API_KEY = aws_secretsmanager_secret.api_key.arn
  }
}

module "transaction_mcp" {
  source = "../../templates/components/mcp_server"

  id = "${local.id}-transaction"
  tags = local.tags
  container_path = "${var.appPath}/containers/transaction_mcp"
  file_trigger = "handler.py"
  health_check = "curl -f http://localhost:8080/healthz >> /proc/1/fd/1 2>&1 || exit 1"
  vpc_id = module.vpc.vpc_id
  alb_subnet_ids = module.vpc.vpc_private_subnet_ids
  alb_sg_id = aws_security_group.alb_sg.id
  alb_health_check = "/healthz"
  ecs_subnet_ids = module.vpc.vpc_private_subnet_ids
  ecs_sg_id = aws_security_group.ecs_tasks_sg.id
  ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
  ecs_execution_policies = [aws_iam_policy.secrets_access_policy.arn]
  environment_variables = {
    API_GATEWAY_BASE_URL = module.data_api.endpoint_url
  }
  secrets_variables = {
    API_KEY = aws_secretsmanager_secret.api_key.arn
  }
}

module "brave_secret" {
  source = "../../templates/modules/secretsmanager_secret"
  name   = "${local.id_path}/brave-secret"
  secret_single_value = var.brave_api_key
  kms_id = module.kms.arn
}

module "fetch_mcp" {
  source = "../../templates/components/mcp_server"
  alb_health_check = "/status"
  id = "${local.id}-fetch"
  tags = local.tags
  container_path = "${var.appPath}/containers/fetch_mcp"
  file_trigger = ""
  health_check = "curl -f http://localhost:8080/status >> /proc/1/fd/1 2>&1 || exit 1"
  vpc_id = module.vpc.vpc_id
  alb_subnet_ids = module.vpc.vpc_private_subnet_ids
  alb_sg_id = aws_security_group.alb_sg.id

  ecs_subnet_ids = module.vpc.vpc_private_subnet_ids
  ecs_sg_id = aws_security_group.ecs_tasks_sg.id
  ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
}

module "brave_mcp" {
  source = "../../templates/components/mcp_server"
  alb_health_check = "/status"
  id = "${local.id}-brave"
  tags = local.tags
  container_path = "${var.appPath}/containers/brave_mcp"
  file_trigger = ""
  health_check = "curl -f http://localhost:8080/status >> /proc/1/fd/1 2>&1 || exit 1"
  vpc_id = module.vpc.vpc_id
  alb_subnet_ids = module.vpc.vpc_private_subnet_ids
  alb_sg_id = aws_security_group.alb_sg.id

  ecs_subnet_ids = module.vpc.vpc_private_subnet_ids
  ecs_sg_id = aws_security_group.ecs_tasks_sg.id
  ecs_task_role_arn = aws_iam_role.ecs_task_role.arn
  ecs_execution_policies = [aws_iam_policy.secrets_access_policy.arn]
  secrets_variables = {
    BRAVE_API_KEY = module.brave_secret.arn
  }
}

