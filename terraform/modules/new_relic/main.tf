# Busca a LabRole pré-existente no ambiente AWS Academy
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_caller_identity" "current" {}

locals {
  lab_role_arn = data.aws_iam_role.lab_role.arn
}

# 1. Bucket S3 para Backup de Falhas do Firehose
resource "aws_s3_bucket" "firehose_backup" {
  bucket        = "nr-metric-stream-backup-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# 2. Kinesis Data Firehose (usando LabRole)
resource "aws_kinesis_firehose_delivery_stream" "newrelic_stream" {
  name        = "newrelic-metrics-delivery-stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url            = "https://aws-api.newrelic.com/cloudwatch-metrics/v1"
    name           = "New Relic Metrics Endpoint"
    access_key     = var.newrelic_license_key
    s3_backup_mode = "FailedDataOnly"
    role_arn       = local.lab_role_arn

    # Configuração de compressão HTTP
    request_configuration {
      content_encoding = "GZIP"
    }

    s3_configuration {
      role_arn           = local.lab_role_arn
      bucket_arn         = aws_s3_bucket.firehose_backup.arn
      compression_format = "GZIP"
    }
  }
}

# 3. CloudWatch Metric Stream (usando LabRole)
resource "aws_cloudwatch_metric_stream" "main" {
  name          = "newrelic-metric-stream"
  role_arn      = local.lab_role_arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.newrelic_stream.arn
  output_format = "opentelemetry0.7"
}