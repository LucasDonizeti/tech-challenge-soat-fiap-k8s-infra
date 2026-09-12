# https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.0"

  repository_name                 = var.repository_name
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
    "arn:aws:iam::${var.account_id}:role/LabRole"
  ]

  tags = var.tags
}
