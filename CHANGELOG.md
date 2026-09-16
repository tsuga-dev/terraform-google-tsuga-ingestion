# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Secret Manager secrets use automatic replication when `universe_domain` is set, instead of a
  user-managed replica in `region`. Trusted Partner Cloud universes are single-region and reject
  user-managed replication, so the module could not be applied there at all. Unset, the
  replication policy is unchanged, which matters because it cannot be altered after a secret is
  created.
- Changing a value that feeds the generated collector config — `tsuga_intake_url`,
  `collection_interval`, `resource_attributes` — now rolls the Cloud Run services.
  The config is a Secret Manager volume pinned to `latest`, so a new secret version alone left
  the running revisions serving the previous config indefinitely. The rendered config's SHA-256
  is now a template annotation, which makes the revision turn over with it.

### Changed

- `vpc_access` is now required when `universe_domain` is set, and its `egress` must be
  `ALL_TRAFFIC`. Trusted Partner Cloud universes have no default serverless egress. Both are
  enforced by variable validation so they fail at plan time rather than as a Cloud Run API 400.
- With `universe_domain` set, the Cloud Run services pin
  `execution_environment = "EXECUTION_ENVIRONMENT_GEN2"`. Direct VPC egress forces Gen2 there and
  the API returns it, which the module would otherwise plan to remove on every run.
- The documented example universe domain is now `myuniverse.example`. The `3.1.0` entry below
  is left as released.

### Fixed

- The Cloud Run secret reference now uses the secret's `name` (project-number form) rather than
  its `id` (project-ID form). On domain-scoped project IDs such as `universe:my-project`, the
  colon made Cloud Run reject the `secret_key_ref`. This matches what the config volumes did.

## [3.1.0] - 2026-09-16

### Added

- `universe_domain` to run the collectors against a Trusted Partner Cloud universe such as
  Cloud de Confiance by S3NS (`s3nsapis.fr`). It is written into the generated collector
  config, so the Pub/Sub and Cloud Monitoring clients resolve `pubsub.<universe-domain>` and
  `monitoring.<universe-domain>` instead of the `googleapis.com` defaults. Set the matching
  `universe_domain` on the google provider in your root module. Unset, behaviour is
  unchanged. See `examples/trusted-partner-cloud`.
- `otel_collector_image` to override the collector image, for universes where the upstream
  image must be mirrored to a reachable registry. Must be `0.155.0` or later when
  `universe_domain` is set.

### Fixed

- The log sink's Pub/Sub publisher binding now uses the sink's own `writer_identity` instead
  of a hand-built `service-<project-number>@gcp-sa-logging.iam.gserviceaccount.com` address.
  Service agent emails are not spelled that way outside the public `googleapis.com` universe.
  No behaviour change on stock GCP, where the two resolve to the same principal.

## [3.0.2] - 2026-09-16

### Changed

- Upgraded the OTel collector image from `0.150.1` to `0.161.0`. Two upstream behaviour
  changes come with it: `googlecloudmonitoring` now marks CUMULATIVE metrics from Cloud
  Monitoring as monotonic on conversion ([#49804](https://github.com/open-telemetry/opentelemetry-collector-contrib/pull/49804)),
  and `google_cloud_logentry_encoding` no longer emits the deprecated `rpc.jsonrpc.error_code`
  and `rpc.jsonrpc.error_message` attributes ([#22095](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/22095)).
- Renamed the `resourcedetection` processor to `resource_detection` in the generated collector
  config, following its upstream rename in `0.153.0` ([#48525](https://github.com/open-telemetry/opentelemetry-collector-contrib/pull/48525)).

## [3.0.1] - 2026-09-07

### Added

- `vpc_access` to place the collectors on a VPC network/subnetwork using Direct VPC egress.
  With the default `ALL_TRAFFIC` egress mode, all outbound traffic becomes subject to the
  VPC's routes and firewall rules, so you can restrict what the collectors can reach (e.g.
  an FQDN egress allowlist for the Tsuga intake domain). Optional `tags` apply network tags
  for firewall targeting. Unset, behavior is unchanged. See `examples/vpc-egress`.

## [3.0.0] - 2026-09-04

The Tsuga API key is no longer stored in the Terraform state or plan files.

### Changed

- **Breaking:** the module now requires Terraform >= 1.11.
- **Breaking:** `tsuga_api_key` is now optional and declared `ephemeral`; exactly one of `tsuga_api_key` or `tsuga_api_key_secret_id` must be set. The key is written to Secret Manager through the `secret_data_wo` write-only argument, so Terraform never persists it. Because write-only values cannot be diffed, rotating the key now requires incrementing `tsuga_api_key_version` alongside the new value.
- Upgrading from 2.x replaces the Secret Manager secret version once (the write-only argument cannot be reconciled with the previously stored value). State files written by 2.x, including backups, still contain the key in plaintext: you should probably rotate the API key after upgrading.

### Added

- `tsuga_api_key_secret_id` to point the module at an existing Secret Manager secret instead of having it manage one. The key then never passes through Terraform; the module only grants the collector service account access. See `examples/existing-secret`.
- `tsuga_api_key_version`, incremented to write a new secret version when rotating `tsuga_api_key`.

## [2.0.9] - 2026-09-01

### Added

- Added the `resource_attributes` variable for applying stable resource attributes to exported telemetry, including the Collector's own logs and metrics.

## [2.0.8] - 2026-08-27

### Changed

- Widened the `hashicorp/google` provider constraint from `~> 6.47` to `>= 6.47.0, < 8.0.0` so the module works with provider v7, not just v6.

## [2.0.7] - 2026-08-04

### Added

- Added the `log_filter` variable to set an [inclusion filter](https://cloud.google.com/logging/docs/routing/overview#inclusion-filters) on the log sink, so you can route a subset of your GCP logs to Tsuga instead of all of them. Defaults to `null`, which routes everything as before.

### Changed

- The module no longer declares its own `provider "google"` block. Configure the google provider in your root module and it will be inherited, or pass one explicitly with `providers = { google = google.<alias> }`. This makes the module usable with `count`, `for_each`, and `depends_on`, which Terraform rejects on modules that carry their own provider configuration.

### Fixed

- `project` is now set explicitly on the Cloud Run services, the Secret Manager secrets, and the collector service account. These previously inherited the project from the module's own provider block, so removing that block would otherwise have placed them in whatever project the caller's provider pointed at.

## [2.0.6] - 2026-05-07

Releases up to and including v2.0.6 predate this changelog. See the
[GitHub releases](https://github.com/tsuga-dev/terraform-google-tsuga-ingestion/releases)
for their contents.
