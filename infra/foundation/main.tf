locals {
  bucket_name              = "ml-datasets-${var.project_id}-${var.region}"
  registry_repository_name = "ml-experiments-${var.project_id}-${var.region}"
}

resource "google_storage_bucket" "datasets" {
  name     = local.bucket_name
  location = var.region
}

resource "google_artifact_registry_repository" "ml_experiments" {
  location      = var.region
  repository_id = local.registry_repository_name
  description   = "Repository for CNN hybrid experiment images"
  format        = "DOCKER" # porque lo usarás para imágenes Docker
}

