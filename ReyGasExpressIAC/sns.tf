# Tópico SNS para notificar cuando un análisis de preferencias está completo y se requiere un reporte
resource "aws_sns_topic" "reyGasExpress_reports_topic" {
  name = "reyGasExpress-reports-topic-${var.environment}"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Tópico SNS para notificar cuando un reporte está listo para ser enviado por email
resource "aws_sns_topic" "reyGasExpress_email_topic" {
  name = var.email_topic_name

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}