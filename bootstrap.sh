#!/bin/bash
# Полный автоматический bootstrap кластера

set -e

echo "Bootstrap кластера..."

# 1. Создать кластер через Terraform
cd terraform/environments/dev
terraform init
terraform apply -auto-approve

# 2. Подождать готовности кластера
sleep 30

# 3. Установить ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  -f ../../../argocd-values.yaml

# 4. Применить root application
kubectl apply -f ../../../applications.yaml

echo "Bootstrap завершен"
