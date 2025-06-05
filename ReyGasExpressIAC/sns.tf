# Tópico SNS para notificar cuando un análisis de preferencias está completo y se requiere un reporte
resource "aws_sns_topic" "reyGasExpress_reports_topic" {
  name = "reyGasExpress-reports-topic-${var.environment}"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}