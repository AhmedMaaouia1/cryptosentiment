output "s3_datalake_bucket_name" {
  value       = aws_s3_bucket.datalake.bucket
  description = "Nom du bucket S3 datalake"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.timeseries.name
  description = "Nom de la table DDB timeseries"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.alerts.arn
  description = "ARN du topic SNS alerts"
}
