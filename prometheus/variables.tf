variable "namespace" { type = string }

variable "prom_service_name" {
  type = string
  default = "prometheus-service"
}

variable "prom_service_port" {
  type = number
  default = 9090
}
