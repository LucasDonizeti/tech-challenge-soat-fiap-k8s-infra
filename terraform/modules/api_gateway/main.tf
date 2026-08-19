# ------------------------------------------------------------------------------
# API Gateway HTTP API v2
# ------------------------------------------------------------------------------

# 1. API Gateway
resource "aws_apigatewayv2_api" "main_gateway" {
  name          = var.name
  protocol_type = "HTTP"

  tags = var.tags
}

# 2. Security Group para o VPC Link
resource "aws_security_group" "vpc_link_sg" {
  name        = "${var.name}-vpc-link-sg"
  description = "Security group para VPC Link do API Gateway"
  vpc_id      = var.vpc_id

  ingress {
    description = "Tráfego do API Gateway via VPC Link"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-vpc-link-sg" })
}

# 3. VPC Link para conectar o API Gateway aos Serviços do EKS (Load Balancer interno)
resource "aws_apigatewayv2_vpc_link" "eks_vpc_link" {
  name               = "${var.name}-vpc-link"
  security_group_ids = [aws_security_group.vpc_link_sg.id]
  subnet_ids         = var.private_subnets
}

# 4. Integração das rotas com o EKS (VPC Link)
resource "aws_apigatewayv2_integration" "eks_integration" {
  api_id             = aws_apigatewayv2_api.main_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.internal_nlb_listener_arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.eks_vpc_link.id
}

# 5. Rota genérica para enviar todas as requisições de negócio ao EKS
resource "aws_apigatewayv2_route" "eks_route" {
  api_id    = aws_apigatewayv2_api.main_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

# 6. Stage Padrão com auto-deploy ativo (Essencial para as rotas funcionarem)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.main_gateway.id
  name        = "$default"
  auto_deploy = true
}
