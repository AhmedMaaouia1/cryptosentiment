# -------------------------
# OUTPUTS DU MODULE DYNAMODB NEWS
# -------------------------

output "table_name" {
  description = "Nom de la table DynamoDB News"
  value       = aws_dynamodb_table.news.name
}

output "table_arn" {
  description = "ARN de la table DynamoDB News"
  value       = aws_dynamodb_table.news.arn
}

output "table_id" {
  description = "ID de la table DynamoDB News"
  value       = aws_dynamodb_table.news.id
}

output "hash_key" {
  description = "Nom de la partition key"
  value       = aws_dynamodb_table.news.hash_key
}

output "range_key" {
  description = "Nom de la sort key"
  value       = aws_dynamodb_table.news.range_key
}
