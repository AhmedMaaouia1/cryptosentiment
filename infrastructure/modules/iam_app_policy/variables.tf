variable "project_prefix" {
  description = "Préfixe du projet (ex: cryptosentiment)"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
}

variable "policy_file_path" {
  description = "Chemin vers le fichier JSON de la policy"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN du bucket S3 à inclure dans la policy"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "Liste des ARNs des tables DynamoDB accessibles par l'application"
  type        = list(string)
}

variable "sns_topic_arn" {
  description = "ARN du topic SNS à inclure dans la policy"
  type        = string
}

variable "attach_to_airflow_user" {
  description = "Attacher la policy à l'utilisateur airflow-user"
  type        = bool
  default     = false
}

variable "airflow_user_name" {
  description = "Nom de l'utilisateur IAM Airflow"
  type        = string
  default     = "airflow-user"
}

variable "attach_to_github_actions_role" {
  description = "Attacher la policy au rôle GitHub Actions OIDC"
  type        = bool
  default     = false
}

variable "github_actions_role_name" {
  description = "Nom du rôle IAM GitHub Actions"
  type        = string
  default     = "github-actions-role"
}

variable "tags" {
  description = "Tags à appliquer à la policy IAM"
  type        = map(string)
  default     = {}
}
