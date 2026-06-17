data "google_dns_managed_zone" "zone" {
  project = var.project_id
  name    = var.dns_zone_name
}

resource "google_dns_record_set" "a" {
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.zone.name
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas      = [var.ip_address]
}
