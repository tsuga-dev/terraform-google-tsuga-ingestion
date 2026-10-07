locals {
  # One googlecloudmonitoring receiver per prefix: the receiver drops its whole scrape when any
  # single metric type errors, so a shared receiver lets one bad type blank every prefix.
  gcp_metric_prefixes = [
    # Compute
    "compute.googleapis.com/",
    "container.googleapis.com/",
    "autoscaler.googleapis.com/",
    # Serverless Compute
    "run.googleapis.com/",
    "cloudfunctions.googleapis.com/",
    "appengine.googleapis.com/",
    # Messaging
    "pubsub.googleapis.com/",
    # Data Warehouse & Analytics
    "bigquery.googleapis.com/",
    # Databases
    "cloudsql.googleapis.com/",
    "redis.googleapis.com/",
    "bigtable.googleapis.com/",
    "firestore.googleapis.com/",
    "spanner.googleapis.com/",
    "alloydb.googleapis.com/",
    # Storage
    "storage.googleapis.com/",
    "filestore.googleapis.com/",
    # Networking
    "loadbalancing.googleapis.com/",
    "networkservices.googleapis.com/",
    "networksecurity.googleapis.com/",
    "dns.googleapis.com/",
    "vpn.googleapis.com/",
    "router.googleapis.com/",
    "interconnect.googleapis.com/",
    # AI / ML
    "aiplatform.googleapis.com/",
    # Orchestration
    "composer.googleapis.com/",
    "cloudtasks.googleapis.com/",
    "cloudscheduler.googleapis.com/",
    # Firebase
    "firebaseappcheck.googleapis.com/",
    "firebasedatabase.googleapis.com/",
    "firebasehosting.googleapis.com/",
    # Custom & User-defined Metrics
    "custom.googleapis.com/",
    "external.googleapis.com/",
    "logging.googleapis.com/user/",
    # GKE / Kubernetes
    "kubernetes.io/",
    # CI/CD & Artifact Management
    "cloudbuild.googleapis.com/",
    "artifactregistry.googleapis.com/",
    # Data Processing
    "dataflow.googleapis.com/",
    "dataproc.googleapis.com/",
    "datastream.googleapis.com/",
    "bigquerystorage.googleapis.com/",
    # Additional Storage & Databases
    "memcache.googleapis.com/",
    "datastore.googleapis.com/",
    # Serverless & Orchestration
    "workflows.googleapis.com/",
    "eventarc.googleapis.com/",
    "batch.googleapis.com/",
    # Security & Identity
    "secretmanager.googleapis.com/",
    "certificatemanager.googleapis.com/",
    # Platform & Quota
    "serviceruntime.googleapis.com/",
    "monitoring.googleapis.com/",
    # TPU / Accelerators
    "tpu.googleapis.com/",
  ]

  gcp_metric_receivers = {
    for prefix in local.gcp_metric_prefixes :
    replace(trimsuffix(replace(prefix, ".googleapis.com", ""), "/"), "/[./]/", "_") => prefix
  }

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
      universe_domain     = var.universe_domain == null ? "" : var.universe_domain
      metric_prefixes     = local.gcp_metric_receivers
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
      universe_domain     = var.universe_domain == null ? "" : var.universe_domain
      metric_prefixes     = local.gcp_metric_receivers
    }
  ) : null
}

check "collection_types_validation" {
  assert {
    condition     = var.enable_logs || var.enable_metrics
    error_message = "At least one collection type must be enabled. Set either enable_logs = true or enable_metrics = true (or both)."
  }
}
