output "service_name" {
  value = google_cloud_run_v2_service.service.name
}

output "url" {
  value = google_cloud_run_v2_service.service.uri
}

output "service_account_email" {
  value = google_service_account.runtime.email
}
