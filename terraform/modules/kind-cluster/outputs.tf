output "cluster_name" {
  description = "Имя созданного кластера"
  value       = kind_cluster.this.name
}

output "cluster_endpoint" {
  description = "API endpoint кластера"
  value       = kind_cluster.this.endpoint
}

output "client_certificate" {
  description = "Client certificate для подключения"
  value       = kind_cluster.this.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key для подключения"
  value       = kind_cluster.this.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate кластера"
  value       = kind_cluster.this.cluster_ca_certificate
  sensitive   = true
}
