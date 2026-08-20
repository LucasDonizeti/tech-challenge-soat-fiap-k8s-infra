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
  value       = aws_security_group.nodes.id
}

output "node_group_autoscaling_group_names" {
  description = "Lista com o nome dos Auto Scaling Groups criados pelo Node Group do EKS"
  value       = aws_eks_node_group.main.resources[0].autoscaling_groups[*].name
}