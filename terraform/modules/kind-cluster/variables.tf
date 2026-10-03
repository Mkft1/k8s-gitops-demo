variable "cluster_name" {
  description = "Имя кластера Kind"
  type        = string
  default     = "kubernetes-learning"
}

variable "worker_count" {
  description = "Количество worker нод"
  type        = number
  default     = 2
}

variable "kubeconfig_path" {
  description = "Путь к kubeconfig файлу"
  type        = string
  default     = "~/.kube/config"
}
