variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "cloud_run_service" { type = string }
variable "domain_name" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
