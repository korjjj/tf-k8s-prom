terraform {
  required_version = ">= 1.10.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

resource "google_service_account" "default" {
  display_name	= "Service Account"
  account_id	= var.account_id
  project	= var.project
}

resource "google_compute_network" "vpc" {
  project			= var.project
  name				= "${var.project}-net"
  auto_create_subnetworks	= "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.69.0.0/24"
  project	= var.project
}

# export GOOGLE_APPLICATION_CREDENTIALS=some.json
resource "google_container_cluster" "primary" {
  name			= var.cluster_name
  location		= var.zone
  project		= var.project
  initial_node_count	= 1
  deletion_protection	= false
  network		= google_compute_network.vpc.name
  subnetwork		= google_compute_subnetwork.subnet.name
  node_config {
    service_account = google_service_account.default.email
    oauth_scopes = [ "https://www.googleapis.com/auth/cloud-platform" ]
  }
}

data "google_client_config" "provider" {}
data "google_container_cluster" "cluster_creds" {
  depends_on	= [ google_container_cluster.primary ]

  name		= var.cluster_name
  location	= var.zone
  project	= var.project
}

output "host"	{ value = "https://${data.google_container_cluster.cluster_creds.endpoint}" }
output "cacert"	{ value = base64decode(data.google_container_cluster.cluster_creds.master_auth[0].cluster_ca_certificate) }
output "token" {
  value = data.google_client_config.provider.access_token
  sensitive = true
}

# dump kubeconfig for port-forward etc
locals {
  kubeconfig = <<EOL
    apiVersion: v1
    kind: Config
    current-context: ${var.cluster_name}
    preferences: {}
    clusters:
    - cluster:
        certificate-authority-data: ${google_container_cluster.primary.master_auth[0].cluster_ca_certificate}
        server: https://${google_container_cluster.primary.endpoint}
      name: ${var.cluster_name}
    contexts:
    - context:
        cluster: ${var.cluster_name}
        user: ${var.cluster_name}
      name: ${var.cluster_name}
    users:
    - name: ${var.cluster_name}
      user:
        token: ${data.google_client_config.provider.access_token}
  EOL 
}

resource "local_sensitive_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = "kubeconfig.yml"
  file_permission = "0600"
}
