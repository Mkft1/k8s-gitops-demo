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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
  }
}

# ЯВНАЯ НАСТРОЙКА ПРОВАЙДЕРОВ (Решает проблему с kubeconfig)
provider "kubernetes" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.default.endpoint
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  }
}

provider "kind" {}

# 1. Создаем кластер Kind
resource "kind_cluster" "default" {
  name            = "kubernetes-learning"
  wait_for_ready  = true
  kubeconfig_path = "~/.kube/config"

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

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

# 2. Устанавливаем Cilium
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "kube-system"
  wait       = true
  timeout    = 600

  depends_on = [kind_cluster.default]

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

# 3. Создаем неймспейс для ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [helm_release.cilium]
}

# 4. Устанавливаем ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  wait       = true
  timeout    = 600

  depends_on = [kubernetes_namespace.argocd]

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }
  set {
    name  = "dex.enabled"
    value = "false"
  }
  set {
    name  = "applicationSet.enabled"
    value = "false"
  }
  set {
    name  = "notifications.enabled"
    value = "false"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "512Mi"
  }
}
