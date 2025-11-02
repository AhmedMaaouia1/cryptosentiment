# -------------------------
# DYNAMODB TIMESERIES MODULE
# -------------------------
# Ce module crée une table DynamoDB pour stocker les données de timeseries
# avec une clé de partition (asset) et une clé de tri (timestamp)

locals {
  table_name = "${var.project_prefix}-${var.environment}-timeseries"
}

resource "aws_dynamodb_table" "timeseries" {
  name         = local.table_name
  hash_key     = var.hash_key
  range_key    = var.range_key
  billing_mode = var.billing_mode

  # Attributs obligatoires pour les clés
  attribute {
    name = var.hash_key
    type = "S" # String pour l'asset (ex: "BTC", "ETH")
  }

  attribute {
    name = var.range_key
    type = "N" # Number pour le timestamp
  }

  # Configuration TTL pour expiration automatique
  ttl {
    attribute_name = var.ttl_attribute_name
    enabled        = var.ttl_enabled
  }

  # Restauration point-in-time (backup continu)
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  # Protection contre la suppression accidentelle
  deletion_protection_enabled = var.deletion_protection

  # Tags
  tags = merge(
    var.tags,
    {
      Name        = local.table_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "dynamodb_timeseries"
    }
  )
}
