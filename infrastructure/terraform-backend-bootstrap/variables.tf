variable "project_prefix" {
  description = "Préfixe des ressources"
  type        = string
  default     = "cryptosentiment"
}

variable "environment" {
  description = "Nom d'environnement (ex: dev)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}
