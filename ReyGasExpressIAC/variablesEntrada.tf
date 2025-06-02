# Variables de entrada para WAF

variable "waf_name" {
  description = "Nombre del WAF para ReyGasExpress"
  type        = string
  default     = "reyGasExpress-web-acl"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "rate_limit" {
  description = "Límite de requests por IP"
  type        = number
  default     = 2000
}

#Variables de entrada para CLOUDFRONT
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "cloudfront_distribution_name" {
  description = "Nombre de la distribución CloudFront"
  type        = string
  default     = "reyGasExpress-distribution"
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 para el frontend"
  type        = string
  default     = "reygas-express-frontend"
}

variable "api_gateway_domain" {
  description = "Dominio del API Gateway"
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "Clase de precio para CloudFront"
  type        = string
  default     = "PriceClass_100"  # Solo US, Canada, Europa
}