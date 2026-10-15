variable "cluster_name" {
  type        = string
  description = "Имя Kubernetes кластера"
}

variable "network_id" {
  type        = string
  description = "ID приватной сети"
}

variable "subnet_id" {
  type        = string
  description = "ID приватной подсети"
}

variable "keypair_name" {
  type        = string
  description = "Имя SSH ключа, созданного в консоли VK Cloud"
}

variable "worker_count" {
  type        = number
  description = "Количество worker-нод"
  default     = 1
}

variable "flavor_id" {
  type        = string
  description = "ID конфигурации ВМ"
}
