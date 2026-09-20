terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker" # provider Docker (démo locale)
      version = "~> 3.0"
    }
  }
}

provider "docker" {} # parle au démon Docker local

# L'image est RÉFÉRENCÉE par son nom (construite au préalable : voir UC5 étape 4).
# Terraform ne la build pas ; si elle est absente localement, l'apply échoue.
resource "docker_image" "catalog" {
  name = var.image_name # paramétré via une variable (pas de valeur en dur)
}

resource "docker_container" "catalog" {
  name  = "catalog"
  image = docker_image.catalog.image_id

  ports {
    internal = 8080
    external = var.host_port # port exposé sur l'hôte (paramétrable)
  }
}

# URL de santé : /health est mappé car l'image fixe ASPNETCORE_ENVIRONMENT=Development.
output "catalog_url" {
  value = "http://localhost:${var.host_port}/health"
}
