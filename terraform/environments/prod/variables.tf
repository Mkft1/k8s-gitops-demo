variable "cluster_name" {
  type = string
}

variable "worker_count" {
  type = number
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}
