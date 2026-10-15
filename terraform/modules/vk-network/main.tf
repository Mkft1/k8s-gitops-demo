terraform {
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.18"
    }
  }
}

variable "project_id" { 
  type = string 
}

# 1. Находим внешнюю публичную сеть по флагу external (самый надежный способ)
data "vkcs_networking_network" "extnet" {
  external = true
}

# 2. Создаем роутер
resource "vkcs_networking_router" "router" {
  name                = "k8s-router"
  admin_state_up      = true
  external_network_id = data.vkcs_networking_network.extnet.id
}

# 3. Создаем приватную сеть
resource "vkcs_networking_network" "private" {
  name           = "k8s-private-net"
  admin_state_up = true
}

# 4. Создаем подсеть (CIDR 10.10.0.0/24)
resource "vkcs_networking_subnet" "private" {
  name            = "k8s-private-subnet"
  network_id      = vkcs_networking_network.private.id
  cidr            = "10.10.0.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# 5. Соединяем подсеть с роутером
resource "vkcs_networking_router_interface" "private" {
  router_id = vkcs_networking_router.router.id
  subnet_id = vkcs_networking_subnet.private.id
}

output "network_id" { value = vkcs_networking_network.private.id }
output "subnet_id"  { value = vkcs_networking_subnet.private.id }
output "router_id"  { value = vkcs_networking_router.router.id }
