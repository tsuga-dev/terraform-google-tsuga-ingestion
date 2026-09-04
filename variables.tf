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
  description = "Tsuga API Key for integration. Written to Secret Manager through a write-only argument, so it never appears in the Terraform state or plan. When rotating it, also increment `tsuga_api_key_version`. Mutually exclusive with `tsuga_api_key_secret_id`."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "tsuga_api_key_version" {
  description = "Increment this whenever `tsuga_api_key` changes. Terraform cannot diff the write-only key value, so this number is what triggers writing a new secret version."
  type        = number
  default     = 1
}

variable "tsuga_api_key_secret_id" {
  description = "ID of an existing Secret Manager secret holding the Tsuga API key, in the form `projects/<project>/secrets/<secret-id>`. When set, the key never passes through Terraform: the module manages neither the secret nor its versions, and only grants the collector service account access to it. Mutually exclusive with `tsuga_api_key`."
  type        = string
  default     = null

  validation {
    condition     = (var.tsuga_api_key == null) != (var.tsuga_api_key_secret_id == null)
    error_message = "Set exactly one of tsuga_api_key or tsuga_api_key_secret_id."
  }

  validation {
    condition     = var.tsuga_api_key_secret_id == null || can(regex("^projects/[^/]+/secrets/[^/]+$", var.tsuga_api_key_secret_id))
    error_message = "tsuga_api_key_secret_id must have the form projects/<project>/secrets/<secret-id>."
  }
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

variable "resource_attributes" {
  description = "Stable resource attributes for grouping exported telemetry, such as `service.namespace`, `business.unit`, or `data.classification`."
  type        = map(string)
  default     = {}
  nullable    = false
}
