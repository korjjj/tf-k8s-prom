terraform {
  required_version = ">= 1.10.0"
  required_providers {
    kubernetes	= {
      source	= "hashicorp/kubernetes"
      version	= "2.34.0"
    }
  }
}

# export GOOGLE_APPLICATION_CREDENTIALS
# export TF_VAR_gce_project
module "gce"		{
  source	= "./gce"
  count		= var.gce_enabled == true ? 1 : 0
  project	= var.gce_project
}

provider "kubernetes" {
  host				= var.gce_enabled == true ? module.gce[0].host : null
  cluster_ca_certificate	= var.gce_enabled == true ? module.gce[0].cacert : null
  token				= var.gce_enabled == true ? module.gce[0].token : null

  config_path			= var.gce_enabled == true ? null : var.kubeconfig_path
}

resource "kubernetes_namespace" "monitoring" {
  metadata { name = var.namespace }
}

module "prometheus"		{
  source	= "./prometheus"
  count		= var.prometheus_enabled == true ? 1 : 0
  namespace	= kubernetes_namespace.monitoring.metadata[0].name
}

module "grafana"		{
  source	= "./grafana"
  count		= var.grafana_enabled == true ? 1 : 0
  namespace	= kubernetes_namespace.monitoring.metadata[0].name
}

module "app"		{
  source	= "./app"
  count		= var.app_enabled == true ? 1 : 0
  namespace	= kubernetes_namespace.monitoring.metadata[0].name
}
