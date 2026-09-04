variable "project_id" {
  description = "GCP project ID where the collector runs"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run"
  type        = string
}

variable "prefix" {
  description = "Base name for Cloud Run service and Secret"
  type        = string
  default     = "tsuga"
}

variable "tsuga_api_key_secret_id" {
  description = "Existing Secret Manager secret holding the Tsuga API key (projects/<project>/secrets/<secret-id>). Create it with: printf '%s' \"$API_KEY\" | gcloud secrets create tsuga-api-key --data-file=-"
  type        = string
}

variable "tsuga_intake_url" {
  description = "Tsuga OTLP/HTTP ingestion endpoint"
  type        = string
}
