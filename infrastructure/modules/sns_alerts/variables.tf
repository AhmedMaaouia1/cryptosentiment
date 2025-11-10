variable "project_prefix" {
  description = "Préfixe du projet (ex: cryptosentiment)"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
}

variable "display_name" {
  description = "Nom d'affichage du topic SNS"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "Policy JSON pour la livraison des messages"
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "ID de la clé KMS pour chiffrer les messages (optionnel)"
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Créer un topic FIFO (First-In-First-Out)"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Activer la déduplication basée sur le contenu (FIFO uniquement)"
  type        = bool
  default     = false
}

variable "email_subscriptions" {
  description = "Liste d'adresses email à abonner au topic"
  type        = list(string)
  default     = []
}

variable "sms_subscriptions" {
  description = "Liste de numéros de téléphone à abonner au topic (format E.164)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags à appliquer au topic SNS"
  type        = map(string)
  default     = {}
}
