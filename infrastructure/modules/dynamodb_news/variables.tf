variable "project_prefix" {
  description = "Préfixe du projet (ex: cryptosentiment)"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
}

variable "billing_mode" {
  description = "Mode de facturation DynamoDB"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "Partition key de la table news"
  type        = string
  default     = "pk"
}

variable "range_key" {
  description = "Sort key de la table news"
  type        = string
  default     = "sk"
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
