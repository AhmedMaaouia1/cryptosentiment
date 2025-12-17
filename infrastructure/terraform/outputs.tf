output "s3_datalake_bucket_name" {
  value       = module.s3_datalake.bucket_name
  description = "Nom du bucket S3 datalake"
}

output "dynamodb_prices_table_name" {
  description = "Nom de la table DynamoDB des prix crypto"
  value       = module.dynamodb_timeseries.table_name
}

output "dynamodb_news_table_name" {
  description = "Nom de la table DynamoDB des news et sentiments"
  value       = module.dynamodb_news.table_name
}

output "sns_topic_arn" {
  value       = module.sns_alerts.topic_arn
  description = "ARN du topic SNS alerts"
}
