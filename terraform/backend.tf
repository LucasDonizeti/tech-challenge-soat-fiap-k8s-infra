terraform {
  backend "s3" {
    bucket         = "bucket-tfstate-1029"
    key            = "k8s/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "meu-terraform-state-lock"
    encrypt        = true
  }
}
