variable "project_id" {
  description = "GCP project id."
  type        = string
}

variable "region" {
  description = "Default region for regional resources (Cloud Run, Artifact Registry, serverless NEG)."
  type        = string
  default     = "europe-west2"
}

variable "service_name" {
  description = "Cloud Run service name; also used as the Artifact Registry repo name."
  type        = string
  default     = "terrarun-app"
}

variable "image" {
  description = "Fully-qualified container image (REGION-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG). If empty, a hello-world placeholder is used so the first apply succeeds before CI pushes a real image."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Fully-qualified domain served by the load balancer, e.g. cr.example.com."
  type        = string
}

variable "dns_zone_name" {
  description = "Name of the existing Cloud DNS managed zone that hosts domain_name."
  type        = string
}

variable "min_instances" {
  description = "Cloud Run minimum instances."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Cloud Run maximum instances."
  type        = number
  default     = 5
}

variable "labels" {
  description = "Common labels applied to all supported resources."
  type        = map(string)
  default = {
    app     = "terrarun"
    managed = "terraform"
  }
}
