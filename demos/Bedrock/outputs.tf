output "s3_bucket_name" {
  value = aws_s3_bucket.kb_bucket.bucket
}

output "opensearch_collection_name" {
  value = aws_opensearchserverless_collection.kb_collection.name
}

output "knowledge_base_id" {
  value = aws_bedrockagent_knowledge_base.kb.id
}
