# -------------------------
# OUTPUTS DU MODULE DYNAMODB
# -------------------------

output "table_name" {
  description = "Nom de la table DynamoDB"
  value       = aws_dynamodb_table.timeseries.name
}

output "table_arn" {
  description = "ARN de la table DynamoDB"
  value       = aws_dynamodb_table.timeseries.arn
}

output "table_id" {
  description = "ID de la table DynamoDB"
  value       = aws_dynamodb_table.timeseries.id
}

output "table_stream_arn" {
  description = "ARN du stream DynamoDB (si activé)"
  value       = aws_dynamodb_table.timeseries.stream_arn
}

output "hash_key" {
  description = "Nom de la clé de partition"
  value       = aws_dynamodb_table.timeseries.hash_key
}

output "range_key" {
  description = "Nom de la clé de tri"
  value       = aws_dynamodb_table.timeseries.range_key
}
