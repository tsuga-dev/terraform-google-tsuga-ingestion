module "tsuga_existing_secret_integration" {
  source                  = "../.."
  project_id              = var.project_id
  region                  = var.region
  prefix                  = var.prefix
  tsuga_api_key_secret_id = var.tsuga_api_key_secret_id
  tsuga_intake_url        = var.tsuga_intake_url

  enable_logs    = true
  enable_metrics = true
}
