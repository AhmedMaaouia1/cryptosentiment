# -------------------------
# OUTPUTS DU MODULE IAM
# -------------------------

output "policy_name" {
  description = "Nom de la policy IAM"
  value       = aws_iam_policy.app_minimal.name
}

output "policy_arn" {
  description = "ARN de la policy IAM"
  value       = aws_iam_policy.app_minimal.arn
}

output "policy_id" {
  description = "ID de la policy IAM"
  value       = aws_iam_policy.app_minimal.id
}

output "airflow_user_attached" {
  description = "Indique si la policy est attachée à l'utilisateur Airflow"
  value       = var.attach_to_airflow_user
}

output "github_actions_role_attached" {
  description = "Indique si la policy est attachée au rôle GitHub Actions"
  value       = var.attach_to_github_actions_role
}
