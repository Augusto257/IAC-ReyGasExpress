# Crea el contenedor en s3 donde se guardaran los archivos de nuestro frontend
resource "aws_s3_bucket" "reygas_frontend_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Permite restaurar versiones previas de nuestros archivos en caso de errores o eliminaciones
resource "aws_s3_bucket_versioning" "reygas_frontend_versioning" {
  bucket = aws_s3_bucket.reygas_frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Asegura que todos los datos almacenados en nuestro bucket s3 esten encriptados en reposo
resource "aws_s3_bucket_server_side_encryption_configuration" "reygas_frontend_encryption" {
  bucket = aws_s3_bucket.reygas_frontend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Garantiza que nuestro bucket s3 no sea accesible públicamente desde internet
resource "aws_s3_bucket_public_access_block" "reygas_frontend_pab" {
  bucket = aws_s3_bucket.reygas_frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Bucket S3 para almacenar los datos de análisis/intermedios de preferencias
resource "aws_s3_bucket" "reyGasExpress_analysis_bucket" {
  bucket = "reygas-express-analysis-${var.environment}"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Configuración para bloquear el acceso público al bucket de análisis
resource "aws_s3_bucket_public_access_block" "analysis_bucket_public_access_block" {
  bucket = aws_s3_bucket.reyGasExpress_analysis_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}