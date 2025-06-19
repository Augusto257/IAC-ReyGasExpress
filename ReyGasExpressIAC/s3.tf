# Bucket principal para el frontend (ya está correctamente configurado)
resource "aws_s3_bucket" "reygas_frontend_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "reygas_frontend_versioning" {
  bucket = aws_s3_bucket.reygas_frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reygas_frontend_encryption" {
  bucket = aws_s3_bucket.reygas_frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reygas_frontend_pab" {
  bucket                  = aws_s3_bucket.reygas_frontend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket para análisis de preferencias (ya está correctamente configurado)
resource "aws_s3_bucket" "reyGasExpress_analysis_bucket" {
  bucket = "reygas-express-analysis-${var.environment}"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "analysis_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.reyGasExpress_analysis_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analysis_bucket_encryption" {
  bucket = aws_s3_bucket.reyGasExpress_analysis_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "reyGasExpress_reports_bucket" {
  bucket = var.reports_bucket_name

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "reports_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.reyGasExpress_reports_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports_bucket_encryption" {
  bucket = aws_s3_bucket.reyGasExpress_reports_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "reygas_frontend_failover_bucket" {
  bucket = "${var.s3_bucket_name}-failover-${var.environment}"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "reygas_failover_versioning" {
  bucket = aws_s3_bucket.reygas_frontend_failover_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reygas_failover_encryption" {
  bucket = aws_s3_bucket.reygas_frontend_failover_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reygas_frontend_failover_pab" {
  bucket                  = aws_s3_bucket.reygas_frontend_failover_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}