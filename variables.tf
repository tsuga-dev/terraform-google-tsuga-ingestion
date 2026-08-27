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


variable "vpc_access" {
  description = "Route the collectors' outbound traffic through your own VPC, so whatever receives the telemetry sees it all arriving from a single egress IP (your Cloud NAT) instead of Google's rotating Cloud Run pool - useful for the Tsuga intake, and equally for an OTel gateway or any receiver behind an IP allowlist. Set either `network`/`subnetwork` for direct VPC egress, or `connector` for an existing Serverless VPC Access connector. Egress defaults to ALL_TRAFFIC, which is what sends the export calls through your VPC. Leave null to keep the default Cloud Run egress."
  type = object({
    network    = optional(string)
    subnetwork = optional(string)
    tags       = optional(list(string))
    connector  = optional(string)
    egress     = optional(string, "ALL_TRAFFIC")
  })
  default = null

  validation {
    condition     = var.vpc_access == null ? true : (var.vpc_access.connector != null) != (var.vpc_access.network != null || var.vpc_access.subnetwork != null)
    error_message = "Set either vpc_access.connector (existing Serverless VPC Access connector) or vpc_access.network/subnetwork (direct VPC egress), not both."
  }
}
