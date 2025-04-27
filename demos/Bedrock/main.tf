data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "kb_bucket" {
  bucket = local.s3_bucket_name

  tags = {
    Environment = var.environment
    SID         = var.sid
  }
}

resource "aws_iam_role" "bedrock_kb_role" {
  name = "${var.sid}-bedrock-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "bedrock.amazonaws.com"
      },
      Action = "sts:AssumeRole",
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        },
        ArnLike = {
          "AWS:SourceArn" = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_policy" {
  name = "${var.sid}-bedrock-kb-policy"
  role = aws_iam_role.bedrock_kb_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:ListFoundationModels",
          "bedrock:ListCustomModels",
          "bedrock:InvokeModel",
          "bedrock:RetrieveAndGenerate"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          aws_s3_bucket.kb_bucket.arn,
          "${aws_s3_bucket.kb_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "aoss:APIAccessAll"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "${var.sid}-encryption-policy"
  type        = "encryption"
  description = "Encryption policy for ${var.sid}-collection"

  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.sid}-collection"
        ],
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = "${var.sid}-network-policy"
  type        = "network"
  description = "Network policy for ${var.sid}-collection"

  policy = jsonencode([
    {
      Description = "Allow public access",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/${var.sid}-collection"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_collection" "kb_collection" {
  name             = "${var.sid}-collection"
  type             = "VECTORSEARCH"
  standby_replicas = "DISABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption_policy,
    aws_opensearchserverless_security_policy.network_policy
  ]
}

resource "aws_opensearchserverless_access_policy" "access_policy" {
  name        = "${var.sid}-access-policy"
  type        = "data"
  description = "Access policy for ${var.sid}-collection"

  policy = jsonencode([
    {
      Description = "Access to OpenSearch index"
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${aws_opensearchserverless_collection.kb_collection.name}/*"
          ]
          Permission = [
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:CreateIndex",
            "aoss:DeleteIndex"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${aws_opensearchserverless_collection.kb_collection.name}"
          ]
          Permission = [
            "aoss:DescribeCollectionItems",
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ]
      Principal = [
        aws_iam_role.bedrock_kb_role.arn,
        "arn:aws:sts::997075698610:assumed-role/AWSReservedSSO_AdministratorAccess_b7e6a830400a9ac7/chad@brightkeycloud.com"
      ]
    }
  ])
}

resource "aws_bedrockagent_knowledge_base" "kb" {
  name        = "${var.sid}-knowledge-base"
  role_arn    = aws_iam_role.bedrock_kb_role.arn
  description = "Knowledge base for ${var.sid}"

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v2:0"

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = 1024
          embedding_data_type = "FLOAT32"
        }
      }

      # supplemental_data_storage_configuration {
      #   storage_location {
      #     type = "S3"

      #     s3_location {
      #       uri = "s3://${aws_s3_bucket.kb_bucket.bucket}"
      #     }
      #   }
      # }
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"

    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb_collection.arn
      vector_index_name = local.aoss.vector_index

      field_mapping {
        metadata_field = local.aoss.metadata_field
        text_field     = local.aoss.text_field
        vector_field   = local.aoss.vector_field
      }
    }
  }
}

resource "aws_bedrockagent_data_source" "data_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.kb.id
  name              = "data_source"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = "arn:aws:s3:::${aws_s3_bucket.kb_bucket.bucket}"
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens = 2048
        overlap_percentage = 10
      }
    }
  }
}
