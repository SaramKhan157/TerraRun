resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${var.service_name}-sa"
  display_name = "Runtime SA for ${var.service_name}"
}

resource "google_cloud_run_v2_service" "service" {
  project  = var.project_id
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  labels   = var.labels

  template {
    service_account = google_service_account.runtime.email
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image
      ports {
        container_port = 8080
      }
      env {
        name  = "REGION"
        value = var.region
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 1
        period_seconds        = 5
        failure_threshold     = 5
      }
      liveness_probe {
        http_get {
          path = "/health"
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      # CI replaces the image on each deploy; don't fight it from `terraform apply` in non-CI contexts.
      client,
      client_version,
    ]
  }
}

# The load balancer fronts this service, but the serverless NEG still calls
# Cloud Run via the run.app endpoint, which requires roles/run.invoker.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
