# -------------------------
# DYNAMODB NEWS MODULE
# -------------------------
# Table dédiée au stockage des news et du sentiment
# Utilisée par le DAG analyze_sentiment

locals {
  table_name = "${var.project_prefix}-${var.environment}-news"
}

resource "aws_dynamodb_table" "news" {
  # checkov:skip=CKV_AWS_28: PITR disabled intentionally to stay within free tier
  name         = local.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Partition key
  attribute {
    name = var.hash_key
    type = "S"
  }

  # Sort key
  attribute {
    name = var.range_key
    type = "S"
  }

  # Encryption at rest (AWS managed key)
  server_side_encryption {
    enabled     = true
    kms_key_arn = null
  }

  # TTL optionnel
  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute_name
    }
  }

  # Point-in-time recovery (optionnel)
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  # Protection contre suppression accidentelle
  deletion_protection_enabled = var.deletion_protection

  tags = merge(
    var.tags,
    {
      Name        = local.table_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "dynamodb_news"
    }
  )
}
