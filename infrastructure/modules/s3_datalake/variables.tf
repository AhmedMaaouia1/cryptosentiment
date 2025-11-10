variable "project_prefix" {
  description = "Préfixe du projet (ex: cryptosentiment)"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
}

variable "account_id" {
  description = "ID du compte AWS"
  type        = string
}

variable "enable_versioning" {
  description = "Activer le versioning sur le bucket"
  type        = bool
  default     = false
}

variable "lifecycle_abort_multipart_days" {
  description = "Nombre de jours avant d'abandonner les uploads multipart incomplets"
  type        = number
  default     = 7
}

variable "sse_algorithm" {
  description = "Algorithme de chiffrement côté serveur (AES256 ou aws:kms)"
  type        = string
  default     = "AES256"
}

variable "aws_region" {
  description = "Région AWS du déploiement"
  type        = string
}

variable "kms_key_id" {
  description = "ID de la clé KMS (optionnel, uniquement si sse_algorithm = aws:kms)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags à appliquer au bucket S3"
  type        = map(string)
  default     = {}
}
