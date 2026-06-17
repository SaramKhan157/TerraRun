locals {
  placeholder_image = "us-docker.pkg.dev/cloudrun/container/hello"
  container_image   = var.image != "" ? var.image : local.placeholder_image
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
  repository_id = var.service_name
  labels        = var.labels

  depends_on = [google_project_service.services]
}

module "cloud_run" {
  source = "./modules/cloud-run"

  project_id    = var.project_id
  region        = var.region
  service_name  = var.service_name
  image         = local.container_image
  min_instances = var.min_instances
  max_instances = var.max_instances
  labels        = var.labels

  depends_on = [google_project_service.services]
}

module "load_balancer" {
  source = "./modules/load-balancer"

  project_id        = var.project_id
  region            = var.region
  name              = var.service_name
  cloud_run_service = module.cloud_run.service_name
  domain_name       = var.domain_name
  labels            = var.labels

  depends_on = [google_project_service.services]
}

module "dns" {
  source = "./modules/dns"

  project_id    = var.project_id
  dns_zone_name = var.dns_zone_name
  domain_name   = var.domain_name
  ip_address    = module.load_balancer.ip_address
}
