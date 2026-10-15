module "cluster" {
  source = "../../modules/kind-cluster"

  cluster_name    = var.cluster_name
  worker_count    = var.worker_count
  kubeconfig_path = var.kubeconfig_path
}

# Восстановление мастер-ключа Sealed Secrets
resource "terraform_data" "restore_secrets" {
  triggers_replace = [module.cluster.cluster_name]

  provisioner "local-exec" {
    command = "${path.module}/../../scripts/restore-secrets.sh"
  }

  depends_on = [module.cluster]
}

# Создание Bootstrap Application в ArgoCD
# После установки ArgoCD создается root-app, который заставит ArgoCD синхронизировать все приложения из Git
resource "terraform_data" "bootstrap_argocd" {
  triggers_replace = [module.cluster.cluster_name]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Ждём готовности ArgoCD API..."
      sleep 15
      kubectl apply -f ${path.module}/../../../applications/root-app.yaml
      echo "Bootstrap Application создан. ArgoCD начнёт синхронизацию из Git."
    EOT
  }

  depends_on = [module.cluster, terraform_data.restore_secrets, module.cluster.helm_release_argocd]
}
