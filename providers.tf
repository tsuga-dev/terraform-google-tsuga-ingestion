# Define the required Terraform providers and their versions
terraform {
  required_version = ">= 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 9.0.0"
    }
  }
}
