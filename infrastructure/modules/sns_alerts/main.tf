# -------------------------
# SNS ALERTS MODULE
# -------------------------
# Ce module crée un topic SNS pour envoyer des alertes
# (erreurs, anomalies, notifications)

locals {
  topic_name = "${var.project_prefix}-${var.environment}-alerts"
}

# Création du topic SNS
resource "aws_sns_topic" "alerts" {
  name                        = local.topic_name
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : false
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy

  tags = merge(
    var.tags,
    {
      Name        = local.topic_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "sns_alerts"
    }
  )
}

# -------------------------
# Subscriptions Email (optionnelles)
# -------------------------
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.email_subscriptions)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email_subscriptions[count.index]
}

# -------------------------
# Subscriptions SMS (optionnelles)
# -------------------------
resource "aws_sns_topic_subscription" "sms" {
  count     = length(var.sms_subscriptions)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "sms"
  endpoint  = var.sms_subscriptions[count.index]
}
