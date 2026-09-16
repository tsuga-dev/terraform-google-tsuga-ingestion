resource "google_pubsub_topic" "logs_topic" {
  count   = var.enable_logs ? 1 : 0
  project = var.project_id
  name    = "${var.prefix}-logs-topic"
}

resource "google_pubsub_subscription" "logs_sub" {
  count   = var.enable_logs ? 1 : 0
  project = var.project_id
  name    = "${var.prefix}-logs-push-sub"
  topic   = google_pubsub_topic.logs_topic[0].name

  # When a Cloud Run instance is killed (scale-down or restart), the OTel
  # googlecloudpubsub receiver's gRPC stream breaks. Any pulled-but-unacked
  # messages are redelivered after this deadline. The default (10s) is too
  # short — the collector may not finish exporting before the deadline expires,
  # causing messages to be requeued and reprocessed. A longer deadline reduces
  # re-ingestion churn and the resulting log backlog accumulation.
  ack_deadline_seconds = var.pubsub_ack_deadline_seconds
}

resource "google_pubsub_topic_iam_member" "logs_sa_publishing_permissions" {
  count   = var.enable_logs ? 1 : 0
  project = var.project_id

  topic  = google_pubsub_topic.logs_topic[0].name
  role   = "roles/pubsub.publisher"
  member = google_logging_project_sink.logs_sink[0].writer_identity
}
