# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
