# ADR-001: Выбор Cilium вместо kube-proxy

## Статус
Принято

## Контекст
В стандартных кластерах Kubernetes используется kube-proxy (на базе iptables/IPVS). 
Однако для high-load и современных требований безопасности iptables становится узким местом.

## Решение
Мы выбрали **Cilium** на базе eBPF.
- **Причина 1:** eBPF работает напрямую с ядром Linux, обеспечивая меньшие задержки (latency).
- **Причина 2:** Нативная поддержка Network Policies уровня L7 (HTTP/gRPC), что необходимо для Zero-Trust.
- **Причина 3:** Полная замена kube-proxy (`kubeProxyReplacement: strict`).
