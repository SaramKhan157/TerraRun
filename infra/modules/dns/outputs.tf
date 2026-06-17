output "fqdn" {
  value = trimsuffix(google_dns_record_set.a.name, ".")
}
