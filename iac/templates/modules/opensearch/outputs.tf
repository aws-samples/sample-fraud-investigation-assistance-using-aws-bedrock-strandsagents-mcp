// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

output "opensearch_collection_arn" {
  description = "The name of the collection for the Knowledge Base Open Source Software (OSS) content"
  value       = aws_opensearchserverless_collection.kb_collection.arn
}


output "opensearch_index_name" {
  description = "The name of the OpenSearch index"
  value       = opensearch_index.kb_index.name
}