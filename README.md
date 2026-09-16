# Telemetry Collection Integration - Google Cloud Platform to Tsuga

This module deploys two OTel collectors on Google Cloud Run to collect logs and/or metrics from your GCP account:

- **Logs service** - pulls from a Pub/Sub subscription and scales horizontally based on CPU load. Also creates the Pub/Sub topic, subscription, and log sink.
- **Metrics service** - polls GCP Cloud Monitoring on a configurable interval. Pinned to a single instance to prevent duplicate metric collection.

## Prerequisites

- Download `gcloud` CLI.
- Download `terraform` CLI (>= 1.11).
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

### Tsuga ingestion key handling

There are two ways to pass your Tsuga ingestion key to this module.

Method 1: If you prefer the key never to pass through this module at all, create the secret yourself
and pass a reference to it instead of the key:

```hcl
  tsuga_api_key_secret_id = "projects/your-project/secrets/tsuga-api-key"
```

The module then only grants its collector service account access to that secret; creating
the secret and rotating its value stay on your side. See `examples/existing-secret`.

Method 2: You can also simply pass your ingestion key to this module through a
[write-only argument](https://developer.hashicorp.com/terraform/language/resources/ephemeral/write-only). It won't appear in the Terraform state or plan files. If you choose this method, because Terraform cannot diff a
write-only value, rotation must be done explicitly: set the new key in `tsuga_api_key` and increment
`tsuga_api_key_version`.

### Restricting collector egress

By default the collectors use Cloud Run's direct serverless egress and can reach any
internet destination. To constrain what they can reach, set `vpc_access` to place them on a
VPC of yours using [Direct VPC egress](https://cloud.google.com/run/docs/configuring/vpc-direct-vpc):

```hcl
  vpc_access = {
    network    = "your-network"
    subnetwork = "your-subnetwork"  # must be in the Cloud Run region
    tags       = ["tsuga-collector"] # optional, for firewall targeting
  }
```

With the default `ALL_TRAFFIC` egress mode, every outbound packet is subject to your VPC's
routes and firewall rules. The module creates no network resources; the restriction itself
is yours to define — typically a deny-all egress firewall policy plus an allowlist, using
[FQDN objects](https://cloud.google.com/firewall/docs/about-fqdn-objects) to allow only the
Tsuga intake domain, or a [Secure Web Proxy](https://cloud.google.com/secure-web-proxy/docs/overview)
for the strictest posture.

Two things to keep in mind:

- The collectors also call Google APIs (Pub/Sub, Cloud Monitoring). With `ALL_TRAFFIC`,
  those calls go through your VPC too, so the subnetwork needs
  [Private Google Access](https://cloud.google.com/vpc/docs/private-google-access) (or your
  egress allowlist must include `*.googleapis.com`).
- On a Shared VPC subnet, the Cloud Run service agent needs `roles/compute.networkUser` on
  the subnet.

See `examples/vpc-egress`.

### Trusted Partner Cloud universes

Deploying into a Trusted Partner Cloud universe — [Cloud de Confiance by S3NS](https://documentation.s3ns.fr/docs/overview/tpc-overview),
for instance — takes two settings that must agree:

```hcl
provider "google" {
  project         = var.project_id
  region          = var.region
  universe_domain = "s3nsapis.fr"
}

module "tsuga_ingestion" {
  # ...
  universe_domain = "s3nsapis.fr"
}
```

The provider setting governs the resources Terraform creates. The module variable is written
into the generated collector config, so the collectors' own Pub/Sub and Cloud Monitoring
clients resolve `pubsub.s3nsapis.fr` and `monitoring.s3nsapis.fr` instead of the
`googleapis.com` defaults.

Nothing else in the module needs adapting: API service names are the same across universes,
[only the endpoint FQDNs differ](https://documentation.s3ns.fr/docs/overview/tpc-key-differences).

If the upstream collector image is not reachable from your universe, mirror it to a registry
that is and point `otel_collector_image` at the copy. It must be `0.155.0` or later —
`universe_domain` was added to both receivers in that release.

See `examples/trusted-partner-cloud`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
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
| <a name="input_otel_collector_image"></a> [otel\_collector\_image](#input\_otel\_collector\_image) | Container image for the OTel collectors. Override to pull from a registry reachable from your universe. Must be 0.155.0 or later when `universe_domain` is set. | `string` | `"otel/opentelemetry-collector-contrib:0.161.0"` | no |
| <a name="input_otel_service_account_email"></a> [otel\_service\_account\_email](#input\_otel\_service\_account\_email) | Existing service account for the metrics-collecting Cloud Run service. If not set, one will be created automatically. | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Base name for Cloud Run services and Secrets. | `string` | `"tsuga"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the collector runs. | `string` | n/a | yes |
| <a name="input_pubsub_ack_deadline_seconds"></a> [pubsub\_ack\_deadline\_seconds](#input\_pubsub\_ack\_deadline\_seconds) | Pub/Sub acknowledgement deadline in seconds. Must be between 10 and 600. | `number` | `120` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for Cloud Run. | `string` | n/a | yes |
| <a name="input_resource_attributes"></a> [resource\_attributes](#input\_resource\_attributes) | Stable resource attributes for grouping exported telemetry, such as `service.namespace`, `business.unit`, or `data.classification`. | `map(string)` | `{}` | no |
| <a name="input_tsuga_api_key"></a> [tsuga\_api\_key](#input\_tsuga\_api\_key) | Tsuga API Key for integration. Written to Secret Manager through a write-only argument, so it never appears in the Terraform state or plan. When rotating it, also increment `tsuga_api_key_version`. Mutually exclusive with `tsuga_api_key_secret_id`. | `string` | `null` | no |
| <a name="input_tsuga_api_key_secret_id"></a> [tsuga\_api\_key\_secret\_id](#input\_tsuga\_api\_key\_secret\_id) | ID of an existing Secret Manager secret holding the Tsuga API key, in the form `projects/<project>/secrets/<secret-id>`. When set, the key never passes through Terraform: the module manages neither the secret nor its versions, and only grants the collector service account access to it. Mutually exclusive with `tsuga_api_key`. | `string` | `null` | no |
| <a name="input_tsuga_api_key_version"></a> [tsuga\_api\_key\_version](#input\_tsuga\_api\_key\_version) | Increment this whenever `tsuga_api_key` changes. Terraform cannot diff the write-only key value, so this number is what triggers writing a new secret version. | `number` | `1` | no |
| <a name="input_tsuga_intake_url"></a> [tsuga\_intake\_url](#input\_tsuga\_intake\_url) | TSUGA OTLP/HTTP ingestion endpoint. | `string` | n/a | yes |
| <a name="input_universe_domain"></a> [universe\_domain](#input\_universe\_domain) | Google Cloud universe the collectors talk to, for Trusted Partner Cloud deployments such as Cloud de Confiance by S3NS (`s3nsapis.fr`). Set the same value on the google provider in your root module. Defaults to null, the public `googleapis.com` universe. | `string` | `null` | no |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Routes the collectors' egress through a VPC with Direct VPC egress. Set `network` and/or `subnetwork` (at least one). If you set only `network`, Cloud Run will assume the value of `subnetwork` to be the same. If you set only `subnetwork`, Cloud Run will look up which VPC owns that subnet. `egress` defaults to ALL\_TRAFFIC so all outbound traffic is subject to the VPC's routes and firewall rules; PRIVATE\_RANGES\_ONLY sends only RFC 1918 traffic through the VPC. `tags` applies network tags to the instances for firewall targeting. Defaults to null: the default serverless egress, not routed through any VPC. | <pre>object({<br/>    network    = optional(string)<br/>    subnetwork = optional(string)<br/>    tags       = optional(list(string))<br/>    egress     = optional(string, "ALL_TRAFFIC")<br/>  })</pre> | `null` | no |

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

The Tsuga API key is not stored in the Terraform state or plan files: it is either written to
Secret Manager through a write-only argument (`tsuga_api_key`) or never passes through Terraform
at all (`tsuga_api_key_secret_id`).

State files written by module versions before v3.0.0 (including backups) contain the API key in
plaintext. If you upgraded from such a version, rotate the key afterwards: set the new value in
`tsuga_api_key` and increment `tsuga_api_key_version`.
