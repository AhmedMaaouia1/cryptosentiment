locals {
  account_id     = data.aws_caller_identity.current.account_id
  bucket_name    = "${var.project_prefix}-${var.environment}-${local.account_id}-datalake"
  ddb_table_name = "${var.project_prefix}-${var.environment}-timeseries"
  sns_topic_name = "${var.project_prefix}-${var.environment}-alerts"
}

# -------------------------
# S3 DATALAKE (privé)
# -------------------------
resource "aws_s3_bucket" "datalake" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket                  = aws_s3_bucket.datalake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id
  rule {
    id     = "abort-multipart-after-7d"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# -------------------------
# DYNAMODB TIMESERIES
# PK = asset (S), SK = ts (N), TTL = ttl (N, epoch)
# -------------------------
resource "aws_dynamodb_table" "timeseries" {
  name         = local.ddb_table_name
  hash_key     = "asset"
  range_key    = "ts"
  billing_mode = var.ddb_billing_mode


  attribute {
    name = "asset"
    type = "S" # ex: "BTC"
  }

  attribute {
    name = "ts"
    type = "N" # ex: 1697500000
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false
  }

  deletion_protection_enabled = false
}

# -------------------------
# SNS ALERTS
# -------------------------
resource "aws_sns_topic" "alerts" {
  name = local.sns_topic_name
}

# ====================================================
# IAM POLICY MINIMALE POUR L'APP (S3 + DDB + SNS)
# ====================================================
data "aws_iam_policy_document" "app_minimal" {
  statement {
    sid = "S3Access"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.datalake.arn,
      "${aws_s3_bucket.datalake.arn}/*"
    ]
  }

  statement {
    sid = "DynamoDBAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.timeseries.arn]
  }

  statement {
    sid       = "SNSPublish"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_iam_policy" "app_minimal" {
  name        = "${var.project_prefix}-${var.environment}-app-minimal"
  description = "Accès minimal S3/DDB/SNS pour CryptoSentiment"
  policy      = data.aws_iam_policy_document.app_minimal.json
}

# --- Attachement au user airflow-user (optionnel) ---
data "aws_iam_user" "airflow" {
  count     = var.attach_to_airflow_user ? 1 : 0
  user_name = var.airflow_user_name
}

resource "aws_iam_user_policy_attachment" "airflow_attach" {
  count      = var.attach_iam_locally ? 1 : 0
  user       = data.aws_iam_user.airflow.user_name
  policy_arn = aws_iam_policy.app_minimal.arn
}


# --- Attachement au rôle OIDC GitHub Actions (optionnel) ---
data "aws_iam_role" "gh_oidc" {
  count = var.attach_to_github_actions_role ? 1 : 0
  name  = var.github_actions_role_name
}

resource "aws_iam_role_policy_attachment" "gha_attach" {
  count      = var.attach_to_github_actions_role ? 1 : 0
  role       = data.aws_iam_role.gh_oidc[0].name
  policy_arn = aws_iam_policy.app_minimal.arn
}
