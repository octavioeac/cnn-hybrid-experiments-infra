output "datasets_bucket_url" {
  value       = "gs://${google_storage_bucket.datasets.name}"
  description = "Ruta gs:// del bucket de datasets"
}
