output "datasets_bucket_url" {
  value       = "gs://${google_storage_bucket.datasets.name}"
  description = "Ruta gs:// del bucket de datasets"
}


output "artifact_registry_repo_id" {
  description = "ID lógico del repo en Artifact Registry"
  value       = google_artifact_registry_repository.ml_experiments.repository_id
}

output "artifact_registry_repo_url" {
  description = "URL completa para push/pull de imágenes"
  value       = "${google_artifact_registry_repository.ml_experiments.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ml_experiments.repository_id}"
}