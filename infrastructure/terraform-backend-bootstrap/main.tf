locals {
  account_id        = data.aws_caller_identity.current.account_id
  state_bucket_name = "${var.project_prefix}-tfstates-${local.account_id}"
  lock_table_name   = "${var.project_prefix}-tf-locks"
}

# -------------------------
# S3: bucket pour terraform state
# -------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket_name
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3
    }
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------
# DynamoDB: table de lock
# -------------------------
resource "aws_dynamodb_table" "locks" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
  }

  deletion_protection_enabled = false
}

# IAM Policy for GitHub OIDC Role to access backend
data "aws_iam_role" "gha_oidc" {
  name = "github-actions-role"
}

locals {
  # Charger la policy JSON externe
  tf_backend_template = file("${path.module}/../policies/tf_backend.json")

  # Remplacer dynamiquement les variables à l'intérieur du JSON
  tf_backend_policy_rendered = replace(
    replace(
      replace(
        replace(
          replace(
            local.tf_backend_template,
            "$${state_bucket_arn}", "arn:aws:s3:::${local.state_bucket_name}"
          ),
          "$${ddb_table_name}", local.lock_table_name
        ),
        "$${account_id}", local.account_id
      ),
      "$${aws_region}", var.aws_region
    ),
    "$${project_prefix}", var.project_prefix
  )
}

resource "aws_iam_policy" "tf_backend" {
  name        = "${var.project_prefix}-tf-backend-policy"
  description = "Allow GitHub Actions to access Terraform remote state (S3 + DDB + IAM read)"
  policy      = local.tf_backend_policy_rendered
}



resource "aws_iam_role_policy_attachment" "gha_oidc_backend_attach" {
  role       = data.aws_iam_role.gha_oidc.name
  policy_arn = aws_iam_policy.tf_backend.arn
}
