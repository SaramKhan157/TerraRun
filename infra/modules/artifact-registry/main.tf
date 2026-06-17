resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "Container images for ${var.repository_id}"
  format        = "DOCKER"
  labels        = var.labels
}
