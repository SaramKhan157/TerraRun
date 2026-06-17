locals {
  placeholder_image = "us-docker.pkg.dev/cloudrun/container/hello"
  container_image   = var.image != "" ? var.image : local.placeholder_image

  # Per-workspace overrides. The `default` workspace is treated as prod and
  # keeps the original (unsuffixed) resource names + apex subdomain, so the
  # existing prod state stays in place. Any other workspace (e.g. "staging")
  # gets a -<workspace> suffix on resources and a <workspace>.<domain> hostname.
  is_default_workspace = terraform.workspace == "default"
  name_suffix          = local.is_default_workspace ? "" : "-${terraform.workspace}"
  effective_service    = "${var.service_name}${local.name_suffix}"
  effective_domain     = local.is_default_workspace ? var.domain_name : "${terraform.workspace}.${var.domain_name}"
}

resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "certificatemanager.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "iamcredentials.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id    = var.project_id
  region        = var.region
  repository_id = local.effective_service
  labels        = var.labels

  depends_on = [google_project_service.services]
}

module "cloud_run" {
  source = "./modules/cloud-run"

  project_id    = var.project_id
  region        = var.region
  service_name  = local.effective_service
  image         = local.container_image
  min_instances = var.min_instances
  max_instances = var.max_instances
  labels        = var.labels

  depends_on = [google_project_service.services]
}

module "load_balancer" {
  source = "./modules/load-balancer"

  project_id         = var.project_id
  region             = var.region
  name               = local.effective_service
  cloud_run_service  = module.cloud_run.service_name
  domain_name        = local.effective_domain
  enable_cloud_armor = var.enable_cloud_armor
  labels             = var.labels

  depends_on = [google_project_service.services]
}

module "dns" {
  source = "./modules/dns"

  project_id    = var.project_id
  dns_zone_name = var.dns_zone_name
  domain_name   = local.effective_domain
  ip_address    = module.load_balancer.ip_address
}
