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
# ECR — repositório da imagem da aplicação principal
# ------------------------------------------------------------------------------
module "ecr_oficina_api" {
  source = "./modules/ecr"

  repository_name = "oficina-api"
  account_id      = data.aws_caller_identity.current.account_id

  tags = {
    Project     = "oficina"
    Environment = "prod"
  }
}

# ------------------------------------------------------------------------------
# ECR — repositório da imagem do lambda authorizer
# ------------------------------------------------------------------------------
module "ecr_auth_lambda" {
  source = "./modules/ecr"

  repository_name = "auth-lambda"
  account_id      = data.aws_caller_identity.current.account_id

  tags = {
    Project     = "oficina"
    Environment = "prod"
  }
}

# ------------------------------------------------------------------------------
# API Gateway
# ------------------------------------------------------------------------------
module "api_gateway" {
  source = "./modules/api_gateway"

  name                      = "${var.app_name}-api-gateway"
  vpc_id                    = module.vpc.vpc_id
  vpc_cidr                  = var.vpc_cidr
  private_subnets           = module.vpc.private_subnets
  internal_nlb_listener_arn = var.internal_nlb_listener_arn

  tags = { Project = var.app_name }
}