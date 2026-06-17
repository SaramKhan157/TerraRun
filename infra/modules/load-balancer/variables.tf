variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "cloud_run_service" { type = string }
variable "domain_name" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "enable_cloud_armor" {
  type        = bool
  default     = true
  description = "Attach a Cloud Armor policy (rate limit + OWASP SQLi/XSS) to the backend service."
}
