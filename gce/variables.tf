variable "account_id" {
  type		= string
  default	= "le-k8s-service-account-1"
}

variable "cluster_name" {
  type		= string
  default	= "el-gke-cluster-1"
}

variable "region" {
  type		= string
  default	= "asia-southeast1"
}

variable "zone" {
  type		= string
  default	= "asia-southeast1-c"
}

variable "project" {
  type		= string
# default	= "el-gce-project-1"
}
