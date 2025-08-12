// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

locals {
  id = "${var.appName}-${var.envName}"
  id_path = "/${var.appName}/${var.envName}"
  id_clean = replace(replace("${var.appName}${var.envName}", "-", ""), "_", "")
  db_password=random_password.master_password.result
}

module "kms" {
  source = "../../templates/modules/kms"
  alias = "${local.id}-key"
  description = "KMS key for Fraud Agent Assistant POC"
  roles = []    # TODO: Update MCP fargate role here
}

module "s3_db_data" {
  source = "../../templates/modules/s3_bucket"
  name_prefix = "${local.id}-db-data-"
  kms_key_id = module.kms.arn 
}

resource "aws_s3_object" "db_data_schema" {
  for_each = fileset("${var.dataPath}/schema", "**/*")

  bucket = module.s3_db_data.id
  key    = "schema/${each.value}"
  source = "${var.dataPath}/schema/${each.value}"
  etag   = filemd5("${var.dataPath}/schema/${each.value}")
}

resource "aws_s3_object" "db_data_xlsx" {
  for_each = fileset("${var.dataPath}", "**/*.xlsx")

  bucket = module.s3_db_data.id
  key    = "data/${each.value}"
  source = "${var.dataPath}/${each.value}"
  etag   = filemd5("${var.dataPath}/${each.value}")
}

resource "random_password" "master_password" {
  length           = 12
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_special      = 2
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}

module "vpc" {
  source = "../../templates/modules/vpc"

  name = "${local.id}-vpc"
  cidr_block = var.vpc_cidr_block
  public_subnets_cidr_blocks = var.public_subnets_cidr_blocks
  private_subnets_cidr_blocks = var.private_subnets_cidr_blocks
  interface_endpoint_services = ["bedrock-runtime", "ecr.dkr", "ssm", "ssmmessages", "ec2", "ec2messages", "ecs", "kms", "logs", "lambda", "secretsmanager"]
  gateway_endpoint_services = ["s3", "dynamodb"]
  allow_internet_egress = true
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "${local.id}-api-key"
}

# Store API key in Secrets Manager
resource "aws_secretsmanager_secret" "api_key" {
  name       = "${local.id_path}/api-key"
  kms_key_id = module.kms.arn
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = aws_api_gateway_api_key.api_key.value
}

module "data_api" {
  #checkov:skip=CKV2_AWS_77: "AWS API Gateway Rest API does not need to be attached WAFv2 WebACL for prototype"
  source = "../../templates/modules/apigateway_rest"
  depends_on = [aws_api_gateway_account.main]
  api_name  = "${local.id}-data-api"
  api_spec = jsonencode({
    openapi = "3.0.1"
    info = {
      title   = "Fraud Agent Assistant API"
      version = "1.0"
    },
    security = [{
      api_key = []
    }],
    components = {
      securitySchemes = {
        api_key = {
          type = "apiKey"
          name = "x-api-key"
          in   = "header"
        }
      }
    },
    paths = {
      "/api/merchant" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      } 
      "/api/transaction" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/merchant/details" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/merchant/stats" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/merchant/search" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/merchant/filter-stats" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/merchant/filter-data" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/transaction/authorization" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/transaction/settlement" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/transaction/filter" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
      "/api/transaction/merchant-transactions" = {
        get = {
          security = [{
            api_key = []
          }],
          produces = ["application/json"]
          x-amazon-apigateway-integration = {
            httpMethod           = "POST"
            payloadFormatVersion = "1.0"
            type                 = "AWS_PROXY"
            uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.query_data_function.arn}/invocations"
          }
        }
      }
    }
  })
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on = [module.data_api]
  name = "${local.id}-usage-plan"

  api_stages {
    api_id = module.data_api.rest_api_id
    stage  = "prod"
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }
}

resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  depends_on    = [aws_api_gateway_usage_plan.usage_plan]
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

module "mrch_database" {
  source                = "../../templates/modules/rds_aurora"
  subnet_ids            = module.vpc.vpc_private_subnet_ids
  database_name         = local.id_clean
  master_username       = "master"
  master_password       = local.db_password
  cluster_engine        = "aurora-postgresql"
  cluster_identifier    = local.id_clean
  instance_class        = "db.t3.medium"
  backup_kms            = module.kms.arn 
  security_group_ids    = [aws_security_group.db_sg.id]
  kms_id                = module.kms.arn
}

module "db_secret" {
  source = "../../templates/modules/secretsmanager_secret"
  name   = "${local.id_path}/db-secret"
  secret_values = {
    database_username = "master"
    database_password = local.db_password
    database_name = module.mrch_database.database_name
    port          = "5533"
    environment      = "${var.envName}"
    host          = module.mrch_database.endpoint
  }
  kms_id = module.kms.arn

}

module "opensearch" {
  source                = "../../templates/modules/opensearch"
  kb_oss_collection_name = "${local.id}-kb-collection"
  bedrock_role_arn       = aws_iam_role.agent_role.arn
  index_name             = "${local.id}-policy-index"
}