# ------------------------------------------------------------------------------
# API Gateway HTTP API v2 (Para Service Kubernetes via NodePort)
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

# 4. Target Group (Tipo 'instance' apontando para a porta 30080 do NodePort)
resource "aws_lb_target_group" "eks_nodes_tg" {
  name_prefix = "ofic-"
  port        = 30080
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "TCP" # NLB faz validação em camada TCP na porta do NodePort
    port                = "30080"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# 5. Vínculo Automático e Dinâmico do Auto Scaling Group (ASG) ao Target Group
# Garante que qualquer EC2 criada pelo EKS seja registrada no Target Group automaticamente!
resource "aws_autoscaling_attachment" "asg_attachment_eks" {
  autoscaling_group_name = var.eks_node_group_asg_name
  lb_target_group_arn    = aws_lb_target_group.eks_nodes_tg.arn
}

# 6. NLB Interno
resource "aws_lb" "internal_nlb" {
  name               = "${var.name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnets

  tags = var.tags
}

# 7. Listener do NLB na porta 80
resource "aws_lb_listener" "internal_nlb_listener" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_nodes_tg.arn
  }
}

# 8. Integração do API Gateway com o NLB via VPC Link
resource "aws_apigatewayv2_integration" "eks_integration" {
  api_id             = aws_apigatewayv2_api.main_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.internal_nlb_listener.arn
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.eks_vpc_link.id
}

# 9. Rota genérica
resource "aws_apigatewayv2_route" "eks_route" {
  api_id    = aws_apigatewayv2_api.main_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_integration.id}"
}

# 10. Stage Padrão
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.main_gateway.id
  name        = "$default"
  auto_deploy = true
}
