variable "project_id" {
  type        = string
  description = "VK Cloud Project ID"
}

variable "cluster_name" {
  type        = string
  default     = "hybrid-cloud-prod"
}

variable "keypair_name" {
  type        = string
  description = "Имя SSH ключа из консоли VK Cloud"
}

variable "worker_count" {
  type        = number
  default     = 1
}

variable "flavor_id" {
  type        = string
  description = "ID конфигурации ВМ (4vCPU/8GB)"
}
