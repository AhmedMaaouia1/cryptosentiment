# -------------------------
# OUTPUTS DU MODULE SNS
# -------------------------

output "topic_name" {
  description = "Nom du topic SNS"
  value       = aws_sns_topic.alerts.name
}

output "topic_arn" {
  description = "ARN du topic SNS"
  value       = aws_sns_topic.alerts.arn
}

output "topic_id" {
  description = "ID du topic SNS"
  value       = aws_sns_topic.alerts.id
}

output "topic_owner" {
  description = "Propriétaire du topic SNS (AWS Account ID)"
  value       = aws_sns_topic.alerts.owner
}

output "email_subscriptions_count" {
  description = "Nombre de subscriptions email créées"
  value       = length(var.email_subscriptions)
}

output "sms_subscriptions_count" {
  description = "Nombre de subscriptions SMS créées"
  value       = length(var.sms_subscriptions)
}
