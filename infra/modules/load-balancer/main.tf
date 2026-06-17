resource "google_compute_global_address" "ip" {
  project = var.project_id
  name    = "${var.name}-ip"
}

# ---------------------------------------------------------------------------
# Cloud Armor — rate limit + a couple of preconfigured OWASP WAF rules.
# Free tier: $5/month base + $0.75 per rule. With 4 rules this is ~$8/month.
# ---------------------------------------------------------------------------
resource "google_compute_security_policy" "policy" {
  count   = var.enable_cloud_armor ? 1 : 0
  project = var.project_id
  name    = "${var.name}-armor"

  # Default rule (must exist, lowest priority).
  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  # Throttle clients hammering the service.
  rule {
    action      = "rate_based_ban"
    priority    = 1000
    description = "Rate limit 100 req/min per IP, ban 10 min on breach"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }

  # Block obvious SQL injection attempts (OWASP CRS preconfigured rule).
  rule {
    action      = "deny(403)"
    priority    = 1100
    description = "Block SQLi (OWASP CRS sqli-v33-stable)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
  }

  # Block obvious XSS attempts.
  rule {
    action      = "deny(403)"
    priority    = 1200
    description = "Block XSS (OWASP CRS xss-v33-stable)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  name                  = "${var.name}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.cloud_run_service
  }
}

resource "google_compute_backend_service" "backend" {
  project               = var.project_id
  name                  = "${var.name}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  security_policy = var.enable_cloud_armor ? google_compute_security_policy.policy[0].id : null

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "https" {
  project         = var.project_id
  name            = "${var.name}-https"
  default_service = google_compute_backend_service.backend.id
}

resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = "${var.name}-cert"

  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_target_https_proxy" "https" {
  project          = var.project_id
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.https.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${var.name}-https-fr"
  target                = google_compute_target_https_proxy.https.id
  port_range            = "443"
  ip_address            = google_compute_global_address.ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  labels                = var.labels
}

# HTTP → HTTPS redirect ------------------------------------------------------
resource "google_compute_url_map" "http_redirect" {
  project = var.project_id
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http" {
  project = var.project_id
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  project               = var.project_id
  name                  = "${var.name}-http-fr"
  target                = google_compute_target_http_proxy.http.id
  port_range            = "80"
  ip_address            = google_compute_global_address.ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
  labels                = var.labels
}
