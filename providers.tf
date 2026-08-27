# Define the required Terraform providers and their versions
terraform {
  required_version = ">=1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.47.0, < 8.0.0"
    }
  }
}
