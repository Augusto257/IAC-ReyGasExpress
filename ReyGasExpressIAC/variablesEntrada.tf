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

# Variables de entrada para CLOUDFRONT
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
  default     = "PriceClass_100" # Solo US, Canada, Europa
}

# Variables de entrada para Cognito
variable "cognito_user_pool_name" {
  description = "Nombre del user pool de Cognito"
  type        = string
  default     = "ReyGasExpress-user-pool"
}

variable "cognito_user_pool_client_name" {
  description = "Nombre del cliente del User Pool de Cognito"
  type        = string
  default     = "ReyGasExpress-client"
}

# Variables de entrada para IAM
variable "lambda_execution_role_name" {
  description = "Nombre del rol de ejecución de Lambda"
  type        = string
  default     = "lambda-execution-role-reyGasExpress"
}

variable "lambda_code_path" {
  description = "Ruta base a la carpeta que contiene los archivos ZIP de las lambdas."
  type        = string
  default     = "lambda_code"
}

# Variables de entrada para ApiGateway
variable "api_gateway_name" {
  description = "Nombre de la API Gateway HTTP"
  type        = string
  default     = "ReyGasExpress-API"
}

variable "api_stage_name" {
  description = "Nombre del stage de la API Gateway"
  type        = string
  default     = "dev"
}

# Variable para el EventBridge Bus
variable "event_bus_name" {
  description = "Nombre base para enviar eventos de pedidos procesados."
  type        = string
  default     = "reyGasExpress-orders-bus"
}

# Variables para el bucket S3 de análisis
variable "analysis_bucket_name" {
  description = "Nombre del bucket S3 para almacenar los datos de análisis de preferencias."
  type        = string
  default     = "reygas-express-analysis" # Nombre base del bucket
}

# Variables para el tópico SNS de reportes
variable "reports_topic_name" {
  description = "Nombre del tópico SNS para notificaciones de reportes."
  type        = string
  default     = "reyGasExpress-reports-topic"
}

# Variables para el bucket S3 de reportes
variable "reports_bucket_name" {
  description = "Nombre del bucket S3 para almacenar los reportes de preferencias generados."
  type        = string
  default     = "reygas-express-reports"
}

# Variables para el tópico SNS de email
variable "email_topic_name" {
  description = "Nombre del tópico SNS para notificaciones de envío de reportes por email."
  type        = string
  default     = "reyGasExpress-email-topic"
}

# Variables para la función Lambda "Enviar Reporte por correo"
variable "from_email_address" {
  description = "Dirección de correo electrónico verificada en SES desde la cual se enviarán los reportes."
  type        = string
  default     = "no-reply@tudominio.com"
}

variable "to_email_address" {
  description = "Dirección de correo electrónico a la que se enviarán los reportes."
  type        = string
  default     = "destinatario@example.com"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate to use with CloudFront"
  type        = string
}

# Variables de entrada para RDS PostgreSQL
variable "db_instance_identifier" {
  description = "Identificador único para la instancia RDS PostgreSQL"
  type        = string
  default     = "reygasexpress-db-instance"
}

variable "db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  type        = string
  default     = "reygasdb"
}

variable "db_username" {
  description = "Nombre de usuario maestro para la base de datos PostgreSQL"
  type        = string
  default     = "reygasadmin"
}

variable "db_master_password_secret_name" {
  description = "Nombre del Secret en Secrets Manager que contendrá la contraseña maestra de la DB"
  type        = string
  default     = "reyGasExpress-db-master-password"
}

variable "db_instance_class" {
  description = "Clase de instancia para la base de datos RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Almacenamiento inicial asignado para la base de datos (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Versión del motor de PostgreSQL"
  type        = string
  default     = "12.20"
}

variable "db_skip_final_snapshot" {
  description = "Determina si se omite la creación de un snapshot final al eliminar la DB"
  type        = bool
  default     = true # Cambiar a 'false' en producción
}

variable "db_multi_az" {
  description = "Especifica si se implementa la instancia en Multi-AZ para alta disponibilidad"
  type        = bool
  default     = false # Cambiar a 'true' en producción
}