resource "kubernetes_cluster_role" "prometheus-cluster-role" {
  metadata { name = "prometheus-cluster-role" }
  rule {
    api_groups	= [""]
    resources	= ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs	= ["get", "list", "watch"]
  }
  rule {
    api_groups	= ["extensions"]
    resources	= ["ingresses"]
    verbs	= ["get", "list", "watch"]
  }
  rule {
    non_resource_urls	= ["/metrics"]
    verbs      		= ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus-cluster-role-binding" {
  metadata { name = "prometheus-cluster-role-binding" }
  role_ref {
    api_group	= "rbac.authorization.k8s.io"
    kind	= "ClusterRole"
    name	= "prometheus-cluster-role"
  }
  subject {
    kind	= "ServiceAccount"
    name	= "default"
    namespace	= var.namespace
  }
}

resource "kubernetes_config_map" "prometheus-config-map" {
  metadata {
    name	= "prometheus-config-map"
    namespace	= var.namespace
  }
  data = { "prometheus.yml" = file("${path.module}/prometheus.yml") }
}

resource "kubernetes_deployment" "prometheus-deployment" {
  depends_on = [ kubernetes_config_map.prometheus-config-map ]
  metadata {
    name	= "prometheus-deployment"
    namespace	= var.namespace
    labels	= { app = "prometheus-server" }
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "prometheus-server" } }
    template {
      metadata { labels = { app = "prometheus-server" } }
      spec {
        container {
          name	= "prometheus-server"
          image	= "prom/prometheus:v3.0.1"
          port { container_port = 9090 }
          args	= ["--storage.tsdb.retention.time=1h", "--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus/"]
          volume_mount {
            name	= "prometheus-config-volume"
            mount_path	= "/etc/prometheus/"
          }
          volume_mount {
            name	= "prometheus-storage-volume"
            mount_path	= "/prometheus/"
          }
        }
        volume {
          name	= "prometheus-config-volume"
          config_map { name = kubernetes_config_map.prometheus-config-map.metadata[0].name }
        }
        volume {
          name	= "prometheus-storage-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "prometheus-service" {
  metadata {
    name	= var.prom_service_name
    namespace	= var.namespace
  }
  spec {
    selector	= { app = kubernetes_deployment.prometheus-deployment.spec[0].template[0].metadata[0].labels.app }
    port { port = var.prom_service_port }
  }
}
