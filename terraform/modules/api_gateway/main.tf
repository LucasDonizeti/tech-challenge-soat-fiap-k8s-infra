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
    description = "Trafego do API Gateway via VPC Link"
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

# 3. VPC Link
resource "aws_apigatewayv2_vpc_link" "eks_vpc_link" {
  name               = "${var.name}-vpc-link"
  security_group_ids = [aws_security_group.vpc_link_sg.id]
  subnet_ids         = var.private_subnets
}

# 4. Target Group alterado para o tipo IP
resource "aws_lb_target_group" "eks_nodes_tg" {
  name        = "${var.name}-eks-tg"
  port        = 30080
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = "30080"
  }

  tags = var.tags
}

# 5. Busca automática das subnets privadas para extrair o CIDR/IPs
data "aws_subnet" "private" {
  count = length(var.private_subnets)
  id    = var.private_subnets[count.index]
}

# 6. Registra os blocos de IP/interfaces das subnets privadas no Target Group
resource "aws_lb_target_group_attachment" "eks_ip_attachment" {
  count            = length(data.aws_subnet.private)
  target_group_arn = aws_lb_target_group.eks_nodes_tg.arn
  # Utiliza o primeiro IP util da subnet privada onde os Nodes/Pods residem
  target_id        = cidrhost(data.aws_subnet.private[count.index].cidr_block, 10) 
  port             = 30080
}

# 7. NLB Interno
resource "aws_lb" "internal_nlb" {
  name               = "${var.name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnets

  tags = var.tags
}

# 8. Listener do NLB
resource "aws_lb_listener" "internal_nlb_listener" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_nodes_tg.arn
  }
}

# 9. Integração com VPC Link
resource "aws_apigatewayv2_integration" "eks_integration" {
  api_id             = aws_apigatewayv2_api.main_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.internal_nlb_listener.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.eks_vpc_link.id
}

# 10. Rota genérica
resource "aws_apigatewayv2_route" "eks_route" {
  api_id    = aws_apigatewayv2_api.main_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

# 11. Stage Padrão
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.main_gateway.id
  name        = "$default"
  auto_deploy = true
}