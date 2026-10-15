terraform {
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.18"
    }
  }
}

# 1. Managed Kubernetes Cluster
resource "vkcs_kubernetes_cluster" "this" {
  name                = var.cluster_name
  keypair             = var.keypair_name
  network_id          = var.network_id
  subnet_id           = var.subnet_id
  version             = "1.29" # Актуальная стабильная версия, можно обновить при необходимости
  pods_network_policy = "calico" # Базовая сеть, позже заменим/дополним Cilium если потребуется
  
  # в той же зоне что и подсеть
  availability_zone   = "GZ1" 
}

# 2. Группа нод (воркеры)
resource "vkcs_kubernetes_node_group" "workers" {
  cluster_id        = vkcs_kubernetes_cluster.this.id
  name              = "worker-nodes"
  availability_zone = "GZ1"
  nodes_count       = var.worker_count
  flavor_id         = var.flavor_id

  # Настройки для возможности масштабирования (в т.ч. до 0 на ночь в будущем)
  min_nodes         = 0
  max_nodes         = 3
  enable_autoscale  = false # Пока управляем вручную через terraform или скрипт
}

# Возвращаем ID кластера для использования в других модулях или скриптах
output "cluster_id" {
  value = vkcs_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = vkcs_kubernetes_cluster.this.name
}
