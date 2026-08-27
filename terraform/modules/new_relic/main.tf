# Busca a LabRole pré-existente no ambiente AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}