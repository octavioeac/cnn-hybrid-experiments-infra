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

output "bigquery_dataset_id" {
  description = "ID del dataset en BigQuery"
  value       = google_bigquery_dataset.experiments.dataset_id
}

output "bigquery_dataset_self_link" {
  description = "Self link al dataset de BigQuery"
  value       = google_bigquery_dataset.experiments.self_link
}


# ──────────────── Buckets ────────────────
output "bucket_ml_data" {
  value       = google_storage_bucket.ml_data.name
  description = "GCS bucket for datasets"
}

output "bucket_ml_outputs" {
  value       = google_storage_bucket.ml_outputs.name
  description = "GCS bucket for experiment outputs"
}

output "bucket_ml_logs" {
  value       = google_storage_bucket.ml_logs.name
  description = "GCS bucket for logs"
}

# ──────────────── Pub/Sub ────────────────
output "pubsub_topic_train" {
  value       = google_pubsub_topic.train.name
  description = "Pub/Sub topic for training jobs"
}

output "pubsub_topic_train_dlq" {
  value       = google_pubsub_topic.train_dlq.name
  description = "DLQ Pub/Sub topic for training jobs"
}

output "pubsub_subscription_train_pull" {
  value       = google_pubsub_subscription.train_pull.name
  description = "Pull subscription for training jobs"
}

# ──────────────── Vertex AI ────────────────
output "vertex_ai_dataset_id" {
  value       = google_vertex_ai_dataset.placeholder.id
  description = "ID of the placeholder Vertex AI dataset"
}

output "vertex_ai_dataset_name" {
  value       = google_vertex_ai_dataset.placeholder.name
  description = "Name of the placeholder Vertex AI dataset"
}

output "vertex_ai_endpoint_id" {
  value       = google_vertex_ai_endpoint.ml_endpoint.id
  description = "ID of the Vertex AI endpoint"
}

output "vertex_ai_endpoint_name" {
  value       = google_vertex_ai_endpoint.ml_endpoint.name
  description = "Name of the Vertex AI endpoint"
}

# ──────────────── Service Accounts ────────────────
output "sa_vertex_jobs_email" {
  value       = google_service_account.vertex_jobs.email
  description = "Email of the Service Account for Vertex AI jobs"
}

output "sa_pubsub_publisher_email" {
  value       = google_service_account.pubsub_publisher.email
  description = "Email of the Service Account for Pub/Sub publishing"
}

# ──────────────── Monitoring ────────────────
output "monitoring_dashboard_id" {
  value       = google_monitoring_dashboard.ml_dashboard.id
  description = "ID of the ML Foundation Monitoring Dashboard"
}
