variable "project_prefix" {
  description = "Préfixe des ressources"
  type        = string
  default     = "cryptosentiment"
}

variable "environment" {
  description = "Environnement (dev|staging|prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

# --- DynamoDB ---
variable "ddb_billing_mode" {
  description = "Mode de facturation DDB (PROVISIONED|PAY_PER_REQUEST)"
  type        = string
  default     = "PROVISIONED"
}

variable "ddb_read_capacity" {
  description = "RCU si PROVISIONED"
  type        = number
  default     = 1
}

variable "ddb_write_capacity" {
  description = "WCU si PROVISIONED"
  type        = number
  default     = 1
}

# --- Attachements IAM ---
variable "attach_to_airflow_user" {
  description = "Attacher la policy au user IAM airflow-user ?"
  type        = bool
  default     = true
}

variable "airflow_user_name" {
  description = "Nom du user IAM pour Airflow"
  type        = string
  default     = "airflow-user"
}

variable "attach_to_github_actions_role" {
  description = "Attacher la policy au rôle OIDC GitHub Actions ?"
  type        = bool
  default     = true
}

variable "github_actions_role_name" {
  description = "Nom du rôle IAM OIDC pour GitHub Actions"
  type        = string
  default     = "github-actions-role"
}
