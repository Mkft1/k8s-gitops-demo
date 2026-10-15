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
  kubeconfig_path = pathexpand("~/.kube/config")

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        <<-EOT
          kind: InitConfiguration
          nodeRegistration:
            kubeletExtraArgs:
              node-labels: "ingress-ready=true"
        EOT
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

# 1. Cilium (сеть)
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

# 2. Sealed Secrets контроллер (нужен ДО ArgoCD, чтобы CRD был готов)
resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  namespace  = "kube-system"
  wait       = true
  timeout    = 300
  depends_on = [helm_release.cilium]

  set {
    name  = "fullnameOverride"
    value = "sealed-secrets-controller"
  }
}

# 3. ArgoCD (GitOps движок)
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 600
  depends_on       = [helm_release.sealed_secrets]

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
  set {
    name  = "server.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "server.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "server.resources.limits.memory"
    value = "512Mi"
  }
  set {
    name  = "repoServer.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "repoServer.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "repoServer.resources.limits.memory"
    value = "512Mi"
  }
}
