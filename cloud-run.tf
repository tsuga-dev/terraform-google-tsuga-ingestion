locals {
  otel_collector_image = "otel/opentelemetry-collector-contrib:0.150.1"
}

# Logs and metrics are split into separate services because they have opposite scaling needs:
# the logs service scales horizontally to absorb Pub/Sub backlog, while the metrics service
# must stay at exactly one instance to prevent every replica from independently polling
# Cloud Monitoring and sending duplicate metric data to Tsuga.

resource "google_cloud_run_v2_service" "otel_logs" {
  count               = var.enable_logs ? 1 : 0
  project             = var.project_id
  name                = "${var.prefix}-otel-logs"
  location            = var.region
  deletion_protection = false

  # Explicit empty block to prevent spurious diffs on refresh;
  # GCP returns default values that Terraform would otherwise try to remove.
  scaling {}

  template {
    service_account = local.otel_service_account_email

    scaling {
      min_instance_count = var.logs_min_instances
      max_instance_count = var.logs_max_instances
    }

    dynamic "vpc_access" {
      for_each = var.vpc_access == null ? [] : [var.vpc_access]
      content {
        connector = vpc_access.value.connector
        egress    = vpc_access.value.egress

        dynamic "network_interfaces" {
          for_each = vpc_access.value.connector == null ? [1] : []
          content {
            network    = vpc_access.value.network
            subnetwork = vpc_access.value.subnetwork
            tags       = vpc_access.value.tags
          }
        }
      }
    }

    containers {
      image = local.otel_collector_image
      args  = ["--config=file:/etc/otel/config.yaml"]

      env {
        name = "TSUGA_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.tsuga_secret.name
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
        cpu_idle = false
      }

      volume_mounts {
        name       = "otel-config"
        mount_path = "/etc/otel"
      }

      liveness_probe {
        http_get {
          path = "/"
          port = 13133
        }
        initial_delay_seconds = 30
        period_seconds        = 30
        timeout_seconds       = 5
        failure_threshold     = 3
      }

      startup_probe {
        http_get {
          path = "/"
          port = 13133
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 30
      }
    }

    volumes {
      name = "otel-config"
      secret {
        secret = google_secret_manager_secret.otel_config_logs[0].name
        items {
          version = "latest"
          path    = "config.yaml"
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.otel_config_logs_version
  ]
}

resource "google_cloud_run_v2_service" "otel_metrics" {
  count               = var.enable_metrics ? 1 : 0
  project             = var.project_id
  name                = "${var.prefix}-otel-metrics"
  location            = var.region
  deletion_protection = false

  # Explicit empty block to prevent spurious diffs on refresh;
  # GCP returns default values that Terraform would otherwise try to remove.
  scaling {}

  template {
    service_account = local.otel_service_account_email

    # Exactly one instance to prevent duplicate metric collection.
    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    dynamic "vpc_access" {
      for_each = var.vpc_access == null ? [] : [var.vpc_access]
      content {
        connector = vpc_access.value.connector
        egress    = vpc_access.value.egress

        dynamic "network_interfaces" {
          for_each = vpc_access.value.connector == null ? [1] : []
          content {
            network    = vpc_access.value.network
            subnetwork = vpc_access.value.subnetwork
            tags       = vpc_access.value.tags
          }
        }
      }
    }

    containers {
      image = local.otel_collector_image
      args  = ["--config=file:/etc/otel/config.yaml"]

      env {
        name = "TSUGA_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.tsuga_secret.name
            version = "latest"
          }
        }
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "2Gi"
        }
        cpu_idle = false
      }

      volume_mounts {
        name       = "otel-config"
        mount_path = "/etc/otel"
      }

      liveness_probe {
        http_get {
          path = "/"
          port = 13133
        }
        initial_delay_seconds = 30
        period_seconds        = 30
        timeout_seconds       = 5
        failure_threshold     = 3
      }

      startup_probe {
        http_get {
          path = "/"
          port = 13133
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 30
      }
    }

    volumes {
      name = "otel-config"
      secret {
        secret = google_secret_manager_secret.otel_config_metrics[0].name
        items {
          version = "latest"
          path    = "config.yaml"
        }
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_secret_manager_secret_version.otel_config_metrics_version
  ]
}
