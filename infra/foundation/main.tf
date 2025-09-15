locals {
  bucket_name = "ml-datasets-${var.project_id}-${var.region}"
}

resource "google_storage_bucket" "datasets" {
  name     = local.bucket_name
  location = var.region
}
