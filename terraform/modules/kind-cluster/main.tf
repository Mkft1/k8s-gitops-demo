terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }
}

locals {
  worker_nodes = [for i in range(var.worker_count) : { role = "worker" }]
}

resource "kind_cluster" "this" {
  name            = var.cluster_name
  wait_for_ready  = true
  kubeconfig_path = "~/.kube/config"

  # ЗАПРЕЩАЕМ пересоздание кластера при изменении пути к конфиг или образа
  lifecycle {
    ignore_changes = [
      kubeconfig_path,
      node_image,
      kind_config
    ]
  }

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    dynamic "node" {
      for_each = local.worker_nodes
      content {
        role = node.value.role
      }
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.this.endpoint
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "kube-system"
  wait       = true
  timeout    = 600

  depends_on = [kind_cluster.this]

  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }
  set {
    name  = "operator.replicas"
    value = "1"
  }
}
