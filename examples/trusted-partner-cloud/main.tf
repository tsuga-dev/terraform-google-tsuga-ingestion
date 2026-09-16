module "tsuga_trusted_partner_cloud" {
  source           = "../.."
  project_id       = var.project_id
  region           = var.region
  prefix           = var.prefix
  tsuga_api_key    = var.tsuga_api_key
  tsuga_intake_url = var.tsuga_intake_url

  universe_domain = var.universe_domain

  vpc_access = {
    network    = var.vpc_network
    subnetwork = var.vpc_subnetwork
  }
}
