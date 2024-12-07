
variable "namespace" {
  type		= string
  default	= "le-monitoring-744"
}

resource "kubernetes_namespace" "monitoring" {
  metadata { name = var.namespace }
}
