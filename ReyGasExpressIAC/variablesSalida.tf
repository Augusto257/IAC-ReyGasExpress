# Variables de salida para WAF
output "waf_web_acl_id" {
  description = "ID del WAF Web ACL"
  value       = aws_wafv2_web_acl.reyGasExpress_waf.id
}

output "waf_web_acl_arn" {
  description = "ARN del WAF Web ACL"
  value       = aws_wafv2_web_acl.reyGasExpress_waf.arn
}

# Variables de salida para CLOUDFRONT
output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribución CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.arn
}

output "cloudfront_domain_name" {
  description = "Nombre de dominio de CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted Zone ID de CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.hosted_zone_id
}

# Salidas para el bucket S3 de análisis
output "analysis_bucket_name" {
  description = "Nombre del bucket S3 para los datos de análisis."
  value       = aws_s3_bucket.reyGasExpress_analysis_bucket.id
}

output "analysis_bucket_arn" {
  description = "ARN del bucket S3 para los datos de análisis."
  value       = aws_s3_bucket.reyGasExpress_analysis_bucket.arn
}

# Salidas para el tópico SNS de reportes
output "reports_topic_arn" {
  description = "ARN del tópico SNS de reportes."
  value       = aws_sns_topic.reyGasExpress_reports_topic.arn
}

# Salidas para el bucket S3 de reportes
output "reports_bucket_name" {
  description = "Nombre del bucket S3 para los reportes generados."
  value       = aws_s3_bucket.reyGasExpress_reports_bucket.id
}

output "reports_bucket_arn" {
  description = "ARN del bucket S3 para los reportes generados."
  value       = aws_s3_bucket.reyGasExpress_reports_bucket.arn
}

# Salidas para el tópico SNS de email
output "email_topic_arn" {
  description = "ARN del tópico SNS de email."
  value       = aws_sns_topic.reyGasExpress_email_topic.arn
}

# Esta salida la agregaremos cuando tengamos el dashboard
# output "cloudwatch_dashboard_name" {
#   description = "Nombre del dashboard de CloudWatch creado."
#   value       = aws_cloudwatch_dashboard.reygas_express_dashboard.dashboard_name
# }

# Variables de salida para RDS PostgreSQL
output "db_instance_address" {
  description = "Endpoint de la instancia RDS PostgreSQL"
  value       = aws_db_instance.reygas_postgres_db.address
}

output "db_instance_port" {
  description = "Puerto de la instancia RDS PostgreSQL"
  value       = aws_db_instance.reygas_postgres_db.port
}

output "db_name" {
  description = "Nombre de la base de datos PostgreSQL"
  value       = aws_db_instance.reygas_postgres_db.db_name
}

output "db_username" {
  description = "Nombre de usuario maestro de la base de datos PostgreSQL"
  value       = aws_db_instance.reygas_postgres_db.username
}

output "db_master_password_secret_arn" {
  description = "ARN del Secret en Secrets Manager que contiene la contraseña maestra de la DB"
  value       = aws_secretsmanager_secret.db_master_password.arn
}

# --- NUEVAS SALIDAS PARA VPC/SUBNETS/SECURITY GROUPS ---
output "lambda_subnet_ids" {
  description = "IDs de las subredes asociadas a las Lambdas."
  value       = [aws_subnet.lambda_subnet_1.id, aws_subnet.lambda_subnet_2.id]
}

output "lambda_security_group_id" {
  description = "ID del Security Group para las funciones Lambda."
  value       = aws_security_group.lambda_sg.id
}

output "rds_subnet_ids" {
  description = "IDs de las subredes asociadas a RDS."
  value       = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]
}

output "rds_security_group_id" {
  description = "ID del Security Group para RDS."
  value       = aws_security_group.rds_sg.id
}