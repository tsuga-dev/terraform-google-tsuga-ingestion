locals {
  manage_api_key_secret   = var.tsuga_api_key_secret_id == null
  tsuga_api_key_secret_id = local.manage_api_key_secret ? google_secret_manager_secret.tsuga_secret[0].id : var.tsuga_api_key_secret_id
}

moved {
  from = google_secret_manager_secret.tsuga_secret
  to   = google_secret_manager_secret.tsuga_secret[0]
}

moved {
  from = google_secret_manager_secret_version.secret_version
  to   = google_secret_manager_secret_version.secret_version[0]
}

resource "google_secret_manager_secret" "tsuga_secret" {
  count     = local.manage_api_key_secret ? 1 : 0
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
  count                  = local.manage_api_key_secret ? 1 : 0
  secret                 = google_secret_manager_secret.tsuga_secret[0].id
  secret_data_wo         = var.tsuga_api_key
  secret_data_wo_version = var.tsuga_api_key_version
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = local.tsuga_api_key_secret_id
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
