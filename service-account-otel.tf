resource "google_service_account" "otel" {
  count        = var.otel_service_account_email != null ? 0 : 1
  project      = var.project_id
  account_id   = "${var.prefix}-otel"
  display_name = "OTel Collector for GCP telemetry"
}

locals {
  otel_service_account_email = var.otel_service_account_email != null ? var.otel_service_account_email : try(google_service_account.otel[0].email, "")
}

resource "google_project_iam_member" "otel_roles" {
  project = var.project_id
  for_each = toset([
    "roles/pubsub.subscriber",
    "roles/monitoring.viewer",
    "roles/secretmanager.secretAccessor"
  ])
  role   = each.key
  member = "serviceAccount:${local.otel_service_account_email}"
}
