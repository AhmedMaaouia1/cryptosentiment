# --- Get current AWS account information ---
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# -------------------------
# S3 DATALAKE (MODULE)
# -------------------------
module "s3_datalake" {
  source = "../modules/s3_datalake"

  project_prefix                 = var.project_prefix
  environment                    = var.environment
  account_id                     = local.account_id
  aws_region                     = var.aws_region
  enable_versioning              = false
  lifecycle_abort_multipart_days = 7
  sse_algorithm                  = "AES256"

  tags = {
    Project = "CryptoSentiment"
  }
}

# -------------------------
# DYNAMODB TIMESERIES (MODULE)
# -------------------------
module "dynamodb_timeseries" {
  source = "../modules/dynamodb_timeseries"

  project_prefix         = var.project_prefix
  environment            = var.environment
  billing_mode           = var.ddb_billing_mode
  hash_key               = "asset"
  range_key              = "ts"
  ttl_enabled            = true
  ttl_attribute_name     = "ttl"
  point_in_time_recovery = false
  deletion_protection    = false

  tags = {
    Project = "CryptoSentiment"
  }
}

# -------------------------
# SNS ALERTS (MODULE)
# -------------------------
module "sns_alerts" {
  source = "../modules/sns_alerts"

  project_prefix              = var.project_prefix
  environment                 = var.environment
  display_name                = "CryptoSentiment Alerts"
  fifo_topic                  = false
  content_based_deduplication = false

  # Ajoutez vos emails/SMS ici si nécessaire
  email_subscriptions = []
  sms_subscriptions   = []

  tags = {
    Project = "CryptoSentiment"
  }
}

# ====================================================
# IAM POLICY MINIMALE (MODULE)
# ====================================================
module "iam_app_policy" {
  source = "../modules/iam_app_policy"

  project_prefix                = var.project_prefix
  environment                   = var.environment
  policy_file_path              = "${path.module}/../policies/app_minimal.json"
  s3_bucket_arn                 = module.s3_datalake.bucket_arn
  dynamodb_table_arn            = module.dynamodb_timeseries.table_arn
  sns_topic_arn                 = module.sns_alerts.topic_arn
  attach_to_airflow_user        = var.attach_iam_locally
  airflow_user_name             = "airflow-user"
  attach_to_github_actions_role = var.attach_to_github_actions_role
  github_actions_role_name      = var.github_actions_role_name

  tags = {
    Project = "CryptoSentiment"
  }
}
