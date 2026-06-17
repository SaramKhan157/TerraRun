output "artifact_registry_repo" {
  description = "Artifact Registry repository path used for docker push."
  value       = module.artifact_registry.repository_url
}

output "cloud_run_url" {
  description = "Default Cloud Run URL (revision-suffixed)."
  value       = module.cloud_run.url
}

output "load_balancer_ip" {
  description = "Static external IP serving the HTTPS load balancer."
  value       = module.load_balancer.ip_address
}

output "service_url" {
  description = "Public HTTPS URL served by the load balancer."
  value       = "https://${var.domain_name}"
}
