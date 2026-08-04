resource "google_secret_manager_secret" "tsuga_secret" {
  project   = var.project_id
  secret_id = "${var.prefix}-api-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.tsuga_secret.id
  secret_data = var.tsuga_api_key
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.tsuga_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.otel_service_account_email}"
}

resource "google_secret_manager_secret" "otel_config_logs" {
  count     = var.enable_logs ? 1 : 0
  project   = var.project_id
  secret_id = "${var.prefix}-otel-config-logs"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "otel_config_logs_version" {
  count       = var.enable_logs ? 1 : 0
  secret      = google_secret_manager_secret.otel_config_logs[0].id
  secret_data = local.otel_config_logs_rendered
}

resource "google_secret_manager_secret_iam_member" "otel_config_logs_access" {
  count     = var.enable_logs ? 1 : 0
  secret_id = google_secret_manager_secret.otel_config_logs[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.otel_service_account_email}"
}

resource "google_secret_manager_secret" "otel_config_metrics" {
  count     = var.enable_metrics ? 1 : 0
  project   = var.project_id
  secret_id = "${var.prefix}-otel-config-metrics"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "otel_config_metrics_version" {
  count       = var.enable_metrics ? 1 : 0
  secret      = google_secret_manager_secret.otel_config_metrics[0].id
  secret_data = local.otel_config_metrics_rendered
}

resource "google_secret_manager_secret_iam_member" "otel_config_metrics_access" {
  count     = var.enable_metrics ? 1 : 0
  secret_id = google_secret_manager_secret.otel_config_metrics[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.otel_service_account_email}"
}
