resource "kubernetes_config_map" "grafana-datasources" {
  depends_on = [ kubernetes_namespace.monitoring ]
  metadata {
    name = "grafana-datasources"
    namespace = var.namespace
  }
  data = {
    "grafana-datasources.yaml" = <<EOL
      apiVersion: 1
      datasources:
      - access: proxy
        editable: true
        name: prometheus
        orgId: 1
        type: prometheus
        url: http://${kubernetes_service.prometheus-service.metadata[0].name}.${var.namespace}.svc:${kubernetes_service.prometheus-service.spec[0].port[0].port}
        version: 1
    EOL
  }
}

resource "kubernetes_config_map" "grafana-dashboards" {
  depends_on = [ kubernetes_namespace.monitoring ]
  metadata {
    name = "grafana-dashboards"
    namespace = var.namespace
  }
  data = {
    "grafana-dashboards.yaml" = <<EOL
       apiVersion: 1
       providers:
       - name: golang-app-dashboard
         folder: ''
         type: file
         options:
           path:
            /var/lib/grafana/dashboards
       EOL
  }
}

resource "kubernetes_config_map" "test-dashboard" {
  depends_on = [ kubernetes_namespace.monitoring ]
  metadata {
    name = "test-dashboard"
    namespace = var.namespace
  }
  data = { "test-dashboard.json" = "${file("${path.module}/files/test-dashboard.json")}" }
}

resource "kubernetes_deployment" "grafana-deployment" {
  depends_on = [ kubernetes_namespace.monitoring, kubernetes_config_map.grafana-datasources ]
  metadata {
    name = "grafana-deployment"
    namespace = var.namespace
    labels = { app = "grafana" }
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "grafana" } }
    template {
      metadata { labels = { app = "grafana" } }
      spec {
        container {
          name = "grafana"
          image  = "grafana/grafana:11.4.0-ubuntu"
          port { container_port = 3000 }
          volume_mount {
            name = "grafana-datasources-volume"
            mount_path = "/etc/grafana/provisioning/datasources"
          }
          volume_mount {
            name = "grafana-dashboards-volume"
            mount_path = "/etc/grafana/provisioning/dashboards"
          }
          volume_mount {
            name = "test-dashboard-volume"
            mount_path = "/var/lib/grafana/dashboards"
          }
          volume_mount {
            name = "grafana-storage-volume"
            mount_path = "/var/lib/grafana"
          }
        }
        volume {
          name = "grafana-datasources-volume"
          config_map { name = kubernetes_config_map.grafana-datasources.metadata[0].name }
        }
        volume {
          name = "grafana-dashboards-volume"
          config_map { name = kubernetes_config_map.grafana-dashboards.metadata[0].name }
        }
        volume {
          name = "test-dashboard-volume"
          config_map { name = kubernetes_config_map.test-dashboard.metadata[0].name }
        }
        volume {
          name = "grafana-storage-volume"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana-service" {
  depends_on = [ kubernetes_namespace.monitoring ]
  metadata {
    name = "grafana-service"
    namespace = var.namespace
  }
  spec {
    selector = { app = kubernetes_deployment.grafana-deployment.spec.0.template.0.metadata[0].labels.app }
    port { port = 3000 }
  }
}
