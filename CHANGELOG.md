# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
