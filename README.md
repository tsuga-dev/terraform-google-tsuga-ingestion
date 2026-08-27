# Telemetry Collection Integration - Google Cloud Platform to Tsuga

This module deploys two OTel collectors on Google Cloud Run to collect logs and/or metrics from your GCP account:

- **Logs service** - pulls from a Pub/Sub subscription and scales horizontally based on CPU load. Also creates the Pub/Sub topic, subscription, and log sink.
- **Metrics service** - polls GCP Cloud Monitoring on a configurable interval. Pinned to a single instance to prevent duplicate metric collection.

## Prerequisites

- Download `gcloud` CLI.
- Download `terraform` CLI.
- Perform `gcloud auth login` before performing terraform commands.
- Tsuga API Key.
- Tsuga Intake URL.

## Usage

This module does not configure the google provider; declare it in your root module and the
module inherits it.

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}

module "tsuga_ingestion" {
  source  = "tsuga-dev/tsuga-ingestion/google"
  version = "<version>"

  project_id       = var.project_id
  region           = var.region
  tsuga_api_key    = var.tsuga_api_key
  tsuga_intake_url = var.tsuga_intake_url

  enable_logs    = true
  enable_metrics = true
}
```

At least one of `enable_logs` or `enable_metrics` must be `true`. Every input is documented
below; see the [Tsuga documentation](https://app.tsuga.com/documentation/integrations/gcp/gcp-services-through-opentelemetry)
for the deployment walkthrough and worked examples.

### Sending traffic from your own IP

Cloud Run egresses from a Google-owned IP pool by default. Set `vpc_access` to route the
collectors through your VPC instead, so Tsuga (and any allowlist in front of it) sees the
single static IP of your Cloud NAT:

```hcl
vpc_access = {
  network    = "my-vpc"
  subnetwork = "my-subnet"   # /26 or larger, in the same region as the collectors
  tags       = ["tsuga-collector"]
}
```

The subnet needs a Cloud Router and Cloud NAT with a reserved static IP; the module does not
create them. Use `connector = "<connector-id>"` instead of `network`/`subnetwork` if you
already run a Serverless VPC Access connector. `egress` defaults to `ALL_TRAFFIC` so the
intake calls actually leave through your VPC.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.6 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.47.0, < 8.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.47.0, < 8.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_collection_interval"></a> [collection\_interval](#input\_collection\_interval) | How often to pull metrics from Cloud Monitoring (e.g., 60s). | `string` | `"300s"` | no |
| <a name="input_enable_logs"></a> [enable\_logs](#input\_enable\_logs) | Enable log collection from GCP to Tsuga. | `bool` | `true` | no |
| <a name="input_enable_metrics"></a> [enable\_metrics](#input\_enable\_metrics) | Enable metrics collection from GCP to Tsuga. | `bool` | `true` | no |
| <a name="input_log_filter"></a> [log\_filter](#input\_log\_filter) | Inclusion filter for the log sink, written in the Logging query language (https://cloud.google.com/logging/docs/routing/overview#inclusion-filters). Defaults to null, which routes every log entry in the project to Tsuga. | `string` | `null` | no |
| <a name="input_logs_max_instances"></a> [logs\_max\_instances](#input\_logs\_max\_instances) | Maximum number of logs collector instances. The metrics service always runs as a single instance regardless of this setting. | `number` | `10` | no |
| <a name="input_logs_min_instances"></a> [logs\_min\_instances](#input\_logs\_min\_instances) | Minimum number of logs collector instances to keep warm. | `number` | `1` | no |
| <a name="input_otel_service_account_email"></a> [otel\_service\_account\_email](#input\_otel\_service\_account\_email) | Existing service account for the metrics-collecting Cloud Run service. If not set, one will be created automatically. | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Base name for Cloud Run services and Secrets. | `string` | `"tsuga"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the collector runs. | `string` | n/a | yes |
| <a name="input_pubsub_ack_deadline_seconds"></a> [pubsub\_ack\_deadline\_seconds](#input\_pubsub\_ack\_deadline\_seconds) | Pub/Sub acknowledgement deadline in seconds. Must be between 10 and 600. | `number` | `120` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for Cloud Run. | `string` | n/a | yes |
| <a name="input_tsuga_api_key"></a> [tsuga\_api\_key](#input\_tsuga\_api\_key) | Tsuga API Key for integration. | `string` | n/a | yes |
| <a name="input_tsuga_intake_url"></a> [tsuga\_intake\_url](#input\_tsuga\_intake\_url) | TSUGA OTLP/HTTP ingestion endpoint. | `string` | n/a | yes |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Route the collectors' outbound traffic through your own VPC, so whatever receives the telemetry sees it all arriving from a single egress IP (your Cloud NAT) instead of Google's rotating Cloud Run pool - useful for the Tsuga intake, and equally for an OTel gateway or any receiver behind an IP allowlist. Set either `network`/`subnetwork` for direct VPC egress, or `connector` for an existing Serverless VPC Access connector. Egress defaults to ALL\_TRAFFIC, which is what sends the export calls through your VPC. Leave null to keep the default Cloud Run egress. | <pre>object({<br>    network    = optional(string)<br>    subnetwork = optional(string)<br>    tags       = optional(list(string))<br>    connector  = optional(string)<br>    egress     = optional(string, "ALL_TRAFFIC")<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_logs_service_url"></a> [logs\_service\_url](#output\_logs\_service\_url) | The Cloud Run logs service URL. |
| <a name="output_metrics_service_url"></a> [metrics\_service\_url](#output\_metrics\_service\_url) | The Cloud Run metrics service URL. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Service account used by the OTel collectors. |
<!-- END_TF_DOCS -->

## Examples

See the `examples/` folder.

## Security

Note that for convenience, the Tsuga API key is passed in Terraform state: you can mitigate this by encrypting the Terraform state.
