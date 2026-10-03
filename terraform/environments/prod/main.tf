module "cluster" {
  source = "../../modules/kind-cluster"

  cluster_name    = var.cluster_name
  worker_count    = var.worker_count
  kubeconfig_path = var.kubeconfig_path
}

resource "terraform_data" "restore_secrets" {
  triggers_replace = [module.cluster.cluster_name]

  provisioner "local-exec" {
    command = "${path.module}/../../scripts/restore-secrets.sh"
  }

  depends_on = [module.cluster]
}
