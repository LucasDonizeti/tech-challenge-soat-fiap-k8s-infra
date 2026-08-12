# ==============================================================================
# EKS — Recursos nativos AWS (sem módulo de terceiros)
# AWS Academy: usa LabRole para cluster e nodes
# ==============================================================================

# 1. Cluster EKS
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = "1.36"
  role_arn = "arn:aws:iam::${var.account_id}:role/LabRole"

  vpc_config {
    subnet_ids              = concat(var.public_subnets, var.private_subnets)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = var.tags
}

# 2. Security Group para os nodes
resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group dos nodes EKS"
  vpc_id      = var.vpc_id

  ingress {
    description = "Comunicacao interna entre nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Control plane para nodes"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Permitir trafego do Load Balancer para NodePorts"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-nodes-sg" })
}

# 3. Node Group Gerenciado — nodes ficam nas subnets privadas
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "main"
  node_role_arn   = "arn:aws:iam::${var.account_id}:role/LabRole"
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  tags = var.tags

  depends_on = [aws_eks_cluster.this]
}

# 4. Add-ons
resource "aws_eks_addon" "addons" {
  for_each = toset(["vpc-cni", "kube-proxy", "coredns"])

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# 5. Acesso para a LabRole
resource "aws_eks_access_entry" "lab_role" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = "arn:aws:iam::${var.account_id}:role/LabRole"
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "lab_role_admin" {
  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.lab_role.principal_arn

  access_scope {
    type = "cluster"
  }
}

