# ==============================================================================
# Bootstrap — executar UMA VEZ antes do main
# Cria apenas o backend remoto (S3 + lock)
# Uso: cd terraform/bootstrap && terraform init && terraform apply
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------------------------
# Backend remoto — S3 + lock nativo
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "bucket-tfstate-1029"
  force_destroy = false

  tags = { Name = "terraform-state" }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "meu-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = { Name = "terraform-state-lock" }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}
