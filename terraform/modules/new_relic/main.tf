# Busca a LabRole pré-existente no ambiente AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# 1. Política de leitura geral de métricas do CloudWatch / Infra
resource "aws_iam_role_policy_attachment" "newrelic_read_only" {
  role       = data.aws_iam_role.lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 2. Permissão de acesso direto às métricas do Amazon RDS
resource "aws_iam_role_policy_attachment" "newrelic_rds" {
  role       = data.aws_iam_role.lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

# 3. Permissão de acesso direto às métricas das Funções AWS Lambda
resource "aws_iam_role_policy_attachment" "newrelic_lambda" {
  role       = data.aws_iam_role.lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}