output "ip_address" {
  value = google_compute_global_address.ip.address
}

output "backend_service_id" {
  value = google_compute_backend_service.backend.id
}

output "ssl_certificate_id" {
  value = google_compute_managed_ssl_certificate.cert.id
}
