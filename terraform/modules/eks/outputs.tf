output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "node_security_group_id" {
  description = "SG dos nodes — usado pelo RDS para permitir acesso na porta 3306"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
