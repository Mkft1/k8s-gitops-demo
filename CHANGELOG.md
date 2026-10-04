# Changelog

## [1.0.0] - 2026-10-05
### Added
- Initial project structure with Helm chart for Nginx (security best practices).
- ArgoCD GitOps automation (App of Apps pattern).
- Terraform IaC for Kind cluster with automated Sealed Secrets recovery.
- DevSecOps pipeline (Gitleaks, Kube-linter, Trivy) in GitHub Actions.
- Monitoring stack (VictoriaMetrics, Loki, Grafana) deployed via ArgoCD.
- Environment separation (Dev/Prod) via Helm values and ArgoCD applications.
- Pod Disruption Budgets and Network Policies for high availability and isolation.
