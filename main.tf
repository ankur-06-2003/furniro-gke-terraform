# VPC
resource "google_compute_network" "vpc" {
  name                    = "prod-vpc"
  auto_create_subnetworks = false
}

# Subnet with Secondary IPs (GKE)
resource "google_compute_subnetwork" "subnet" {
  name          = "prod-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/16"

  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.30.0.0/16"
  }
}

# Firewall – External Ports
resource "google_compute_firewall" "external_ports" {
  name    = "gke-allow-external-ports"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "9090","22","3389"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Service Account for GKE Nodes
# use this to create new service account if not exists
# resource "google_service_account" "gke_node_sa" {
#   account_id   = "gke-app-sa"
#   display_name = "GKE Node Service Account"
# }
# use this if you use existing service account
# data "google_service_account" "gke_node_sa" {
#   account_id = "gke-app-sa"
#   project    = var.project
# }


# GKE Cluster (Production)
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  project  = var.project
  # location = var.region // for regional cluster
  location = var.zone  // for zonal cluster
  
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false


  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  release_channel {
    channel = "REGULAR"
  }
}

# Node Pool (Production Nodes)
resource "google_container_node_pool" "primary_nodes" {
  name       = "prod-node-pool"
  project    = var.project
  # location   = var.region // for regional cluster
  location   = var.zone // for zonal cluster
  cluster    = google_container_cluster.gke.name
  node_count = 3

  node_config {
    machine_type    = "e2-medium"
    disk_size_gb    = 100
    disk_type       = "pd-balanced"
    image_type      = "UBUNTU_CONTAINERD"
    service_account = "gke-app-sa@${var.project}.iam.gserviceaccount.com"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = "production"
    }

    tags = ["gke-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
