locals {
  otel_config_logs_rendered = var.enable_logs ? templatefile(
    "${path.module}/templates/otel-config.yaml.tmpl",
    {
      project_id          = var.project_id
      subscription        = "projects/${var.project_id}/subscriptions/${google_pubsub_subscription.logs_sub[0].name}"
      collection_interval = var.collection_interval
      tsuga_intake_url    = var.tsuga_intake_url
      enable_logs         = true
      enable_metrics      = false
      resource_attributes = var.resource_attributes
    }
  ) : null

  otel_config_metrics_rendered = var.enable_metrics ? templatefile(
    "${path.module}/templates/otel-config.yaml.tmpl",
    {
      project_id          = var.project_id
      subscription        = ""
      collection_interval = var.collection_interval
      tsuga_intake_url    = var.tsuga_intake_url
      enable_logs         = false
      enable_metrics      = true
      resource_attributes = var.resource_attributes
    }
  ) : null
}

check "collection_types_validation" {
  assert {
    condition     = var.enable_logs || var.enable_metrics
    error_message = "At least one collection type must be enabled. Set either enable_logs = true or enable_metrics = true (or both)."
  }
}
