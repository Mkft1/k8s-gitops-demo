terraform {
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.18"
    }
  }
}

provider "vkcs" {}

# 1. Сеть 
module "network" {
  source     = "../../modules/vk-network"
  project_id = var.project_id
}

# 2. Кластер Kubernetes
module "cluster" {
  source       = "../../modules/vk-cluster"
  cluster_name = var.cluster_name
  network_id   = module.network.network_id
  subnet_id    = module.network.subnet_id
  keypair_name = var.keypair_name
  worker_count = var.worker_count
  flavor_id    = var.flavor_id
}

output "network_id" { value = module.network.network_id }
output "subnet_id"  { value = module.network.subnet_id }
output "cluster_id" { value = module.cluster.cluster_id }
