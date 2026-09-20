variable "image_name" {
  description = "Image Docker de l'ecommerce-app (Catalog) à déployer"
  type        = string
  default     = "ecommerce-catalog:latest"
}

variable "host_port" {
  description = "Port exposé sur l'hôte pour atteindre le conteneur"
  type        = number
  default     = 8080
}
