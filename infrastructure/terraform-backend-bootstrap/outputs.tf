output "tfstate_bucket_name" {
  description = "Bucket S3 pour le state Terraform"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_bucket_arn" {
  description = "ARN du bucket S3 de state"
  value       = aws_s3_bucket.tfstate.arn
}

output "tf_lock_table_name" {
  description = "Table DynamoDB pour les locks Terraform"
  value       = aws_dynamodb_table.locks.name
}

output "account_id" {
  description = "Account ID AWS"
  value       = data.aws_caller_identity.current.account_id
}
