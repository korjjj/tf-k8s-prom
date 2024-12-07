resource "kubernetes_config_map" "golang-app-code" {
  depends_on = [ kubernetes_namespace.monitoring ]
  metadata {
    name = "golang-app-code"
    namespace = var.namespace
  }
  data = {
    "main.go" = <<EOL
       package main
       import (
          "net/http"
          "github.com/prometheus/client_golang/prometheus/promhttp"
       )
       func main() {
          http.Handle("/metrics", promhttp.Handler())
          http.ListenAndServe(":3232", nil)
       }
     EOL

    "run.sh" = <<EOL
      go mod init
      go mod tidy
      go run .
    EOL
  }
}

resource "kubernetes_deployment" "golang-app-deployment" {
  depends_on = [ kubernetes_namespace.monitoring, kubernetes_config_map.golang-app-code ]
  metadata {
    name = "golang-app-deployment"
    namespace = var.namespace
    labels = { app = "golang-app" }
  }
  spec {
    replicas = 3
    selector { match_labels = { app = "golang-app" } }
    template {
      metadata {
        labels = { app = "golang-app" }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port" = "3232"
        }
      }
      spec {
        container {
          name = "golang-app"
          image  = "golang:1.21-bullseye"
          port { container_port = 3232 }
          working_dir = "/go/src/app"
          command = ["/bin/bash", "run.sh"]

          # two mounts so created dir is rw
          volume_mount {
            name = "golang-app-code-volume"
            mount_path = "/go/src/app/main.go"
            sub_path = "main.go"
          }
          volume_mount {
            name = "golang-app-code-volume"
            mount_path = "/go/src/app/run.sh"
            sub_path = "run.sh"
          }
        }
        volume {
          name = "golang-app-code-volume"
          config_map { name = kubernetes_config_map.golang-app-code.metadata[0].name }
        }
      }
    }
  }
}
