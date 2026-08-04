resource "google_logging_project_sink" "logs_sink" {
  count       = var.enable_logs ? 1 : 0
  project     = var.project_id
  name        = "${var.prefix}-logs-sink"
  description = "Project Sink to route logs from GCP to Tsuga."

  destination            = "pubsub.googleapis.com/${google_pubsub_topic.logs_topic[0].id}"
  filter                 = var.log_filter
  unique_writer_identity = true
}
