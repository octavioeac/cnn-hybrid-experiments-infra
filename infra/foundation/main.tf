locals {
  bucket_name              = "ml-datasets-${var.project_id}-${var.region}"
  registry_repository_name = "ml-experiments-${var.project_id}-${var.region}"
  endpoint_name            = "endpoint_ml-${var.project_id}-${var.region}"
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

resource "google_bigquery_dataset" "experiments" {
  dataset_id = "experiments"
  location   = var.region
}

resource "google_storage_bucket" "ml_data" {
  name     = "${var.project_id}-ml-data"
  location = var.region
}

resource "google_storage_bucket" "ml_outputs" {
  name     = "${var.project_id}-ml-outputs"
  location = var.region
}

resource "google_storage_bucket" "ml_logs" {
  name     = "${var.project_id}-ml-logs"
  location = var.region
}

resource "google_pubsub_topic" "train" {
  name = "ml-train"
}

resource "google_pubsub_topic" "train_dlq" {
  name = "ml-train-dlq"
}

resource "google_pubsub_subscription" "train_pull" {
  name  = "ml-train-pull"
  topic = google_pubsub_topic.train.name
}

resource "google_vertex_ai_dataset" "placeholder" {
  project             = var.project_id
  region            = var.region
  display_name        = "placeholder-tables-dataset"
  metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tables_1.0.0.yaml"
}


resource "google_vertex_ai_endpoint" "ml_endpoint" {
  name         = local.endpoint_name
  display_name = "ml endpoint from vertex ai endpoint"
  description  = "A sample vertex endpoint"
  location     = var.region
  region       = var.region
}

resource "google_service_account" "vertex_jobs" {
  account_id   = "sa-vertex-jobs"
  display_name = "Service Account for Vertex AI Jobs"
}

resource "google_service_account" "pubsub_publisher" {
  account_id   = "sa-pubsub-publisher"
  display_name = "Publisher for ML Topics"
}


resource "google_monitoring_dashboard" "ml_dashboard" {
  dashboard_json = <<EOT
  {
    "displayName": "ML Foundation Dashboard",
    "gridLayout": { "columns": 2, "widgets": [] }
  }
  EOT
}
