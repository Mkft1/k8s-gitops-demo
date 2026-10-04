#!/bin/bash
set -e # Останавливаем выполнение при любой ошибке

echo "Запуск полного bootstrap кластера..."

# 1. Создаем инфраструктуру через Terraform
echo "1/3: Создание кластера Kind, Cilium и восстановление ключей Sealed Secrets..."
cd terraform/environments/dev
terraform init -input=false
terraform apply -auto-approve
cd ../../..

# 2. Ждем, пока кластер стабилизируется и скрипт restore-secrets отработает
echo "2/3: Ожидание готовности кластера (30 сек)..."
sleep 30

# 3. Применяем корневое ArgoCD приложение (App of Apps)
echo "3/3: Применение корневого ArgoCD Application..."
kubectl apply -f applications.yaml

echo "Bootstrap успешно завершен"
echo "Проверь статус всех приложений: kubectl get applications -n argocd"
echo "Для доступа к Grafana: kubectl port-forward svc/vm-stack-grafana -n monitoring 3000:80"
