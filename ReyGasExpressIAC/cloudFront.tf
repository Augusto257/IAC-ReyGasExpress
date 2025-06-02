# Garantiza que nuestro bucket s3 de frontend este protegido y solo sea accesible a través
# de nuestra distribución CloudFront.
resource "aws_cloudfront_origin_access_control" "reygas_oac" {
  name                          = "reyGasExpress-OAC"
  description                   = "Origin Access Control for ReyGasExpress S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior              = "always"
  signing_protocol              = "sigv4"
}

# Introduce una pausa de 60 segundos en el procesos de despliegue de Terraform
resource "null_resource" "waf_propagation_delay" {
  depends_on = [aws_wafv2_web_acl.reyGasExpress_waf]

  provisioner "local-exec" {
    command = "powershell.exe -Command \"Start-Sleep -Seconds 60\""
  }
  triggers = {
    waf_id = aws_wafv2_web_acl.reyGasExpress_waf.id
  }
}

# Crea la distribución de Amazon CloudFront
resource "aws_cloudfront_distribution" "reygas_distribution" {

  # Define el bucket s3 como origen para el contenido de mi frontend
  origin {
    domain_name = aws_s3_bucket.reygas_frontend_bucket.bucket_domain_name
    origin_id   = "S3-${aws_s3_bucket.reygas_frontend_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.reygas_oac.id
  }

  # Permite que CloudFront dirija tráfico a un API Gateway
  dynamic "origin" {
    for_each = var.api_gateway_domain != "" ? [1] : []
    content {
      domain_name = var.api_gateway_domain
      origin_id   = "API-Gateway"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  web_acl_id          = aws_wafv2_web_acl.reyGasExpress_waf.arn

  # Define como CloudFront maneja las solicitudes para el resto de nuestro contenido
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.reygas_frontend_bucket.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Detecta que todas las solicitudes dirigidas a la ruta /api/
  dynamic "ordered_cache_behavior" {
    for_each = var.api_gateway_domain != "" ? [1] : []
    content {
      path_pattern           = "/api/*"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      target_origin_id       = "API-Gateway"
      compress               = true
      viewer_protocol_policy = "https-only"

      forwarded_values {
        query_string = true
        headers      = ["Authorization", "Content-Type"]
        cookies {
          forward = "none"
        }
      }

      min_ttl     = 0
      default_ttl = 0
      max_ttl     = 0
    }
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["PE"] # Solo Perú para ReyGasExpress
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_s3_bucket_public_access_block.reygas_frontend_pab,
    aws_cloudfront_origin_access_control.reygas_oac,
    null_resource.waf_propagation_delay
  ]
}

# Esta política asegura que solo nuestra distribución de CloudFront tenga permiso para leer
# archivos de nuestro bucket s3
resource "aws_s3_bucket_policy" "reygas_bucket_policy" {
  bucket = aws_s3_bucket.reygas_frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.reygas_frontend_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.reygas_distribution.arn
          }
        }
      }
    ]
  })
}