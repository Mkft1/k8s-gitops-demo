# Security Policy

## Reporting a Vulnerability
If you discover a security vulnerability in this project, please contact Mk.ft.1@yandex.com. Do not open a public issue.

## Security Features
- All secrets encrypted with Bitnami Sealed Secrets + SOPS (age) backup.
- CI/CD pipeline blocks insecure code (Gitleaks, Kube-linter, Trivy).
- Containers run as non-root (`runAsUser: 101`) with read-only root filesystem.
- Network Policies restrict pod-to-pod traffic.
- Resource limits enforced to prevent denial-of-service (DoS) via resource exhaustion.
