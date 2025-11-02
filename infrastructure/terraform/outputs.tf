output "s3_datalake_bucket_name" {
  value       = module.s3_datalake.bucket_name
  description = "Nom du bucket S3 datalake"
}

output "dynamodb_table_name" {
  value       = module.dynamodb_timeseries.table_name
  description = "Nom de la table DDB timeseries"
}

output "sns_topic_arn" {
  value       = module.sns_alerts.topic_arn
  description = "ARN du topic SNS alerts"
}
