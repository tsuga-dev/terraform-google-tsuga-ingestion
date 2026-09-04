terraform {
  required_version = ">= 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.47.0, < 8.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
