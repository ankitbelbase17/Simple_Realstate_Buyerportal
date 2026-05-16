# ============================================================================
# Terraform Configuration: Local Docker Infrastructure
# ============================================================================
# This Terraform script provisions the Docker containers locally.
# It demonstrates Infrastructure as Code (IaC) principles for the DevOps project.
#
# Usage:
#   cd terraform
#   terraform init
#   terraform plan
#   terraform apply
# ============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # Uses the default Docker socket
  # On Linux:   unix:///var/run/docker.sock
  # On Windows: npipe:////.//pipe//docker_engine
}

# ── Network ────────────────────────────────────────────────────────────────────
resource "docker_network" "portal_network" {
  name = "buyer-portal-network"
}

# ── Application Image (built from Dockerfile) ────────────────────────────────
resource "docker_image" "app" {
  name = "buyer-portal:latest"
  build {
    context    = "${path.module}/.."
    dockerfile = "Dockerfile"
    tag        = ["buyer-portal:latest"]
  }
}

# ── Application Container ─────────────────────────────────────────────────────
resource "docker_container" "app" {
  name  = "buyer-portal-app-tf"
  image = docker_image.app.image_id

  ports {
    internal = 5000
    external = 5000
  }

  env = [
    "PORT=5000",
    "JWT_SECRET=free-tier-demo-secret"
  ]

  networks_advanced {
    name = docker_network.portal_network.name
  }

  restart = "unless-stopped"
}

# ── Prometheus Container ──────────────────────────────────────────────────────
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

resource "docker_container" "prometheus" {
  name  = "buyer-portal-prometheus-tf"
  image = docker_image.prometheus.image_id

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = abspath("${path.module}/../monitoring/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.portal_network.name
  }

  depends_on = [docker_container.app]
  restart    = "unless-stopped"
}

# ── Grafana Container ─────────────────────────────────────────────────────────
resource "docker_image" "grafana" {
  name = "grafana/grafana-oss:latest"
}

resource "docker_container" "grafana" {
  name  = "buyer-portal-grafana-tf"
  image = docker_image.grafana.image_id

  ports {
    internal = 3000
    external = 3001
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=admin",
    "GF_USERS_ALLOW_SIGN_UP=false"
  ]

  volumes {
    host_path      = abspath("${path.module}/../monitoring/grafana/provisioning/datasources")
    container_path = "/etc/grafana/provisioning/datasources"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${path.module}/../monitoring/grafana/provisioning/dashboards")
    container_path = "/etc/grafana/provisioning/dashboards"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${path.module}/../monitoring/grafana/dashboards")
    container_path = "/var/lib/grafana/dashboards"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.portal_network.name
  }

  depends_on = [docker_container.prometheus]
  restart    = "unless-stopped"
}

# ── Outputs ────────────────────────────────────────────────────────────────────
output "app_url" {
  value       = "http://localhost:5000"
  description = "Buyer Portal Application URL"
}

output "prometheus_url" {
  value       = "http://localhost:9090"
  description = "Prometheus Monitoring URL"
}

output "grafana_url" {
  value       = "http://localhost:3001"
  description = "Grafana Dashboard URL (admin/admin)"
}
