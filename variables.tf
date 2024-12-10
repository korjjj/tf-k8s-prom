variable "gce_enabled"  {
  type		= bool
  default	= true
}

variable "gce_project"	{
  type		= string
  default	= ""
}

variable "kubeconfig_path" {
  type		= string
  default	= "kubeconfig.yml"
}

variable "namespace" {
  type		= string
  default	= "le-monitoring-744"
}

variable "prometheus_enabled"  {
  type		= bool
  default	= true
}

variable "grafana_enabled"  {
  type		= bool
  default	= true
}

variable "app_enabled"  {
  type		= bool
  default	= true
}
