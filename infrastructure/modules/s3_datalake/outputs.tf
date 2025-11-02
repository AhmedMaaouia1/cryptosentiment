# -------------------------
# OUTPUTS DU MODULE S3
# -------------------------

output "bucket_name" {
  description = "Nom du bucket S3 datalake"
  value       = aws_s3_bucket.datalake.bucket
}

output "bucket_arn" {
  description = "ARN du bucket S3 datalake"
  value       = aws_s3_bucket.datalake.arn
}

output "bucket_id" {
  description = "ID du bucket S3 datalake"
  value       = aws_s3_bucket.datalake.id
}

output "bucket_region" {
  description = "Région du bucket S3"
  value       = var.aws_region
}

output "bucket_domain_name" {
  description = "Domain name du bucket S3"
  value       = aws_s3_bucket.datalake.bucket_domain_name
}
