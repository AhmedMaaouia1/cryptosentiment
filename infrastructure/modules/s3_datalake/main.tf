# -------------------------
# S3 DATALAKE MODULE
# -------------------------
# Ce module crée un bucket S3 sécurisé pour le datalake
# avec encryption, access block, et lifecycle rules

locals {
  bucket_name = "${var.project_prefix}-${var.environment}-${var.account_id}-datalake"
}

# Création du bucket S3
resource "aws_s3_bucket" "datalake" {
  bucket = local.bucket_name

  tags = merge(
    var.tags,
    {
      Name        = local.bucket_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "s3_datalake"
    }
  )
}

# Bloquer tous les accès publics
resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ownership controls (BucketOwnerEnforced pour désactiver les ACLs)
resource "aws_s3_bucket_ownership_controls" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Chiffrement côté serveur
resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_id
    }
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    id     = "abort-multipart-after-${var.lifecycle_abort_multipart_days}d"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.lifecycle_abort_multipart_days
    }
  }
}

# Versioning (optionnel)
resource "aws_s3_bucket_versioning" "datalake" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.datalake.id

  versioning_configuration {
    status = "Enabled"
  }
}
