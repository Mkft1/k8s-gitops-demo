#!/bin/bash
set -euo pipefail

echo "Восстановление секретов..."

# Явно указываем путь к kubeconfig, чтобы kubectl не смотрел на localhost:8080
export KUBECONFIG=~/.kube/config

ENCRYPTED_KEY_FILE="$(dirname "$0")/../../secrets/master-key.dev.enc.yaml"

if [ ! -f "$ENCRYPTED_KEY_FILE" ]; then
    echo "Файл $ENCRYPTED_KEY_FILE не найден!"
    exit 1
fi

if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "Кластер недоступен. Текущий KUBECONFIG=$KUBECONFIG"
    kubectl cluster-info
    exit 1
fi

echo "Расшифровка и применение мастер-ключа"
sops -d "$ENCRYPTED_KEY_FILE" | kubectl apply -f -

echo "Перезапуск sealed-secrets controller..."
kubectl rollout restart deployment/sealed-secrets-controller -n kube-system || echo "Controller еще не установлен"

echo "Мастер-ключ восстановлен"
