data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.app_name}-cluster"
}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name             = "${var.app_name}-vpc"
  cidr             = var.vpc_cidr
  azs              = ["${var.region}a", "${var.region}b"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]
  cluster_name     = local.cluster_name

  tags = { Project = var.app_name }
}

# ------------------------------------------------------------------------------
# EKS
# ------------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  account_id      = data.aws_caller_identity.current.account_id

  tags = { Project = var.app_name }
}

# ------------------------------------------------------------------------------
# ECR — repositório da imagem da aplicação
# ------------------------------------------------------------------------------
module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name                 = "oficina-api"
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = true

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Manter apenas as 5 ultimas imagens"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }
    ]
  })

  repository_read_write_access_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  ]

  tags = {
    Project     = "oficina"
    Environment = "prod"
  }
}
