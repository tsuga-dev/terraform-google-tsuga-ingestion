variable "project_id" {
  description = "GCP project ID where the collector runs."
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run."
  type        = string
}

variable "prefix" {
  description = "Base name for Cloud Run services and Secrets."
  type        = string
  default     = "tsuga"
}

variable "collection_interval" {
  description = "How often to pull metrics from Cloud Monitoring (e.g., 60s)."
  type        = string
  default     = "300s"
}

variable "tsuga_intake_url" {
  description = "TSUGA OTLP/HTTP ingestion endpoint."
  type        = string
}

variable "tsuga_api_key" {
  description = "Tsuga API Key for integration."
  type        = string
  sensitive   = true
}

variable "enable_logs" {
  description = "Enable log collection from GCP to Tsuga."
  type        = bool
  default     = true
}

variable "enable_metrics" {
  description = "Enable metrics collection from GCP to Tsuga."
  type        = bool
  default     = true
}

variable "logs_min_instances" {
  description = "Minimum number of logs collector instances to keep warm."
  type        = number
  default     = 1
}

variable "logs_max_instances" {
  description = "Maximum number of logs collector instances. The metrics service always runs as a single instance regardless of this setting."
  type        = number
  default     = 10
  nullable    = true
}

variable "log_filter" {
  description = "Inclusion filter for the log sink, written in the Logging query language (https://cloud.google.com/logging/docs/routing/overview#inclusion-filters). Defaults to null, which routes every log entry in the project to Tsuga."
  type        = string
  default     = null
}

variable "otel_service_account_email" {
  description = "Existing service account for the metrics-collecting Cloud Run service. If not set, one will be created automatically."
  type        = string
  default     = null
}

variable "pubsub_ack_deadline_seconds" {
  description = "Pub/Sub acknowledgement deadline in seconds. Must be between 10 and 600."
  type        = number
  default     = 120
}

