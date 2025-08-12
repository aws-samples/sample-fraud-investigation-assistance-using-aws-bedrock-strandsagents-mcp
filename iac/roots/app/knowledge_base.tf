// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

locals {
  bedrock_service_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/bedrock.amazonaws.com/AWSServiceRoleForAmazonBedrock"
  partition             = data.aws_partition.this.partition
}

data "aws_partition" "this" {}

resource "time_sleep" "iam_consistency_delay" {
  create_duration = "120s"
}

module "s3_kb" {
  source = "../../templates/modules/s3_bucket"
  name_prefix = "${local.id}-fraud-kb-bucket-"
  kms_key_id = module.kms.arn 
}

#resource "aws_s3_object" "kb-policy-file" {
#  bucket     = module.s3_kb.id
#  key        = "policies.json"
#  source     = "${var.dataPath}/knowledge-base/policies.json"
#}

resource "aws_s3_object" "kb_files" {
  for_each = fileset("${var.dataPath}/knowledge-base", "**/*")

  bucket = module.s3_kb.id
  key    = each.value
  source = "${var.dataPath}/knowledge-base/${each.value}"
  etag   = filemd5("${var.dataPath}/knowledge-base/${each.value}")
}

resource "aws_iam_policy" "agent_s3_policy" {
  name = "${local.id}-agent-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = [
          module.s3_kb.arn,
          "${module.s3_kb.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = [module.kms.arn]
      }
    ]
  })
}

# Attach the S3 policy to the agent role
resource "aws_iam_role_policy_attachment" "agent_s3_policy_attachment" {
  role       = aws_iam_role.agent_role.name
  policy_arn = aws_iam_policy.agent_s3_policy.arn
}

resource "aws_iam_role" "kb_access_role" {
  name = "${local.id}-kb-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_oss_policy" {
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_${local.id}"
  role = aws_iam_role.agent_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["aoss:*"]
        Effect   = "Allow"
        Resource = [module.opensearch.opensearch_collection_arn]
      }
    ]
  })
}

resource "aws_iam_policy" "kb_access_policy" {
  name = "${local.id}-kb-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
        Action   = "bedrock:Retrieve"
        Effect   = "Allow"
        Resource = "${aws_bedrockagent_knowledge_base.fraud_kb.arn}"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          module.s3_kb.arn,
          "${module.s3_kb.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Resource = ["*"],
        Condition = {
            "ForAnyValue:StringEquals": {
                "kms:ResourceAliases": ["alias/${module.kms.alias}"]
            }
        }
      },
      {
        Effect = "Allow",
        Action = ["aoss:*"],
        Resource = [
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:index/${module.opensearch.opensearch_index_name}",
          "arn:aws:aoss:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:index/${module.opensearch.opensearch_index_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_kb_access" {
  role       = aws_iam_role.kb_access_role.name
  policy_arn = aws_iam_policy.kb_access_policy.arn
}

# Generate Open search artifacts

resource "aws_opensearchserverless_access_policy" "kb_data_access_policy" {
  name = "${local.id}-kb-access-policy"
  type = "data"
  policy = jsonencode([
  {
    Rules = [
      {
        ResourceType = "index",
        Resource     = ["index/${local.id}-kb-collection/*"],
        Permission   = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:UpdateIndex",
          "aoss:WriteDocument"
        ]
      },
      {
        ResourceType = "collection",
        Resource     = ["collection/${local.id}-kb-collection"],
        Permission   = [
          "aoss:CreateCollectionItems",
          "aoss:DescribeCollectionItems",
          "aoss:DeleteCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:*"
        ]
      }
    ],
    Principal = [
      aws_iam_role.kb_access_role.arn,
      local.bedrock_service_role
    ]
  }
  ])
}


resource "aws_bedrockagent_knowledge_base" "fraud_kb" {
  name = "${local.id}-fraud-kb"
  role_arn = aws_iam_role.agent_role.arn
  
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
    }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = module.opensearch.opensearch_collection_arn
      vector_index_name = module.opensearch.opensearch_index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [time_sleep.iam_consistency_delay]
}

resource "aws_bedrockagent_data_source" "fraud_kb_data_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.fraud_kb.id
  name              = "${local.id}-DataSource"
  data_deletion_policy = "DELETE"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = module.s3_kb.arn
    }
  }
}
