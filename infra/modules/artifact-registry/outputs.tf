output "repository_id" {
  value = google_artifact_registry_repository.repo.repository_id
}

output "repository_url" {
  description = "Hostname/path prefix used when tagging images."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}
