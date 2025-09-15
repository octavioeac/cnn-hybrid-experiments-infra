terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.33" }
  }
  backend "gcs" {} # opcional si usas estado remoto
}

provider "google" {
  project = var.project_id
  region  = var.region
}
