variable "project_prefix" {
  description = "Préfixe du projet (ex: cryptosentiment)"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
}

variable "billing_mode" {
  description = "Mode de facturation DynamoDB (PROVISIONED ou PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "Clé de partition (hash key)"
  type        = string
  default     = "asset"
}

variable "range_key" {
  description = "Clé de tri (range key)"
  type        = string
  default     = "ts"
}

variable "ttl_enabled" {
  description = "Activer le TTL sur la table"
  type        = bool
  default     = true
}

variable "ttl_attribute_name" {
  description = "Nom de l'attribut TTL"
  type        = string
  default     = "ttl"
}

variable "point_in_time_recovery" {
  description = "Activer la restauration point-in-time"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protection contre la suppression accidentelle"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags à appliquer à la table DynamoDB"
  type        = map(string)
  default     = {}
}
