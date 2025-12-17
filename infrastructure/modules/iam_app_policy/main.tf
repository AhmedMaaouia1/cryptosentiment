# ====================================================
# IAM APP POLICY MODULE
# ====================================================
# Ce module crée une policy IAM minimale pour l'application
# avec accès S3, DynamoDB et SNS

locals {
  policy_name = "${var.project_prefix}-${var.environment}-app-minimal"

  # Charger le template de policy et remplacer les variables
  policy_template = file(var.policy_file_path)

  policy_rendered = replace(
    replace(
      replace(
        local.policy_template,
        "$${bucket_arn}", var.s3_bucket_arn
      ),
      "$${dynamodb_arns}", jsonencode(var.dynamodb_table_arns)
    ),
    "$${sns_arn}", var.sns_topic_arn
  )
}

# Création de la policy IAM
resource "aws_iam_policy" "app_minimal" {
  name        = local.policy_name
  description = "Accès minimal S3/DDB/SNS pour ${var.project_prefix}"
  policy      = local.policy_rendered

  tags = merge(
    var.tags,
    {
      Name        = local.policy_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "iam_app_policy"
    }
  )
}

# -------------------------
# Attachement à l'utilisateur Airflow (optionnel)
# -------------------------
data "aws_iam_user" "airflow" {
  count     = var.attach_to_airflow_user ? 1 : 0
  user_name = var.airflow_user_name
}

resource "aws_iam_user_policy_attachment" "airflow_attach" {
  # checkov:skip=CKV_AWS_40: User attachment is intentional for local Airflow development
  count = var.attach_to_airflow_user ? 1 : 0

  user       = data.aws_iam_user.airflow[0].user_name
  policy_arn = aws_iam_policy.app_minimal.arn

  depends_on = [aws_iam_policy.app_minimal]
}

# -------------------------
# Attachement au rôle GitHub Actions OIDC (optionnel)
# -------------------------
data "aws_iam_role" "github_actions" {
  count = var.attach_to_github_actions_role ? 1 : 0
  name  = var.github_actions_role_name
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  count = var.attach_to_github_actions_role ? 1 : 0

  role       = data.aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.app_minimal.arn

  depends_on = [aws_iam_policy.app_minimal]
}
