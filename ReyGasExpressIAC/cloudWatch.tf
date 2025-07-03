resource "aws_cloudwatch_dashboard" "reygas_express_dashboard" {
  dashboard_name = "ReyGasExpress-Application-Overview-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: Visión General de Errores de Lambda (Métrica Estándar)
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "reyGasExpress-processOrder-${var.environment}", { "label": "Errores Procesar Pedido" }],
            ["AWS/Lambda", "Errors", "FunctionName", "reyGasExpress-analyzePreferences-${var.environment}", { "label": "Errores Analizar Preferencias" }],
            ["AWS/Lambda", "Errors", "FunctionName", "reyGasExpress-generateReport-${var.environment}", { "label": "Errores Generar Reporte" }],
            ["AWS/Lambda", "Errors", "FunctionName", "reyGasExpress-sendEmailReport-${var.environment}", { "label": "Errores Enviar Email" }],
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "Errores de Funciones Lambda"
          period      = 300 # 5 minutos
          stat        = "Sum"
        }
      },
      # Widget 2: Uso de RAM (Métrica Estándar - Invocaciones vs Memoria)
      # Lambda no expone directamente "MemoryUtilization" como una métrica de CloudWatch.
      # La métrica más relevante es "Duration" (cuánto tiempo se ejecuta) vs "MemorySize" (cuánta memoria tiene asignada).
      # Puedes deducir un alto uso de RAM si la duración es consistently alta o si hay timeouts.
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "reyGasExpress-processOrder-${var.environment}", { "label": "Duración Procesar Pedido", "yAxis": "left" }],
            ["AWS/Lambda", "Duration", "FunctionName", "reyGasExpress-analyzePreferences-${var.environment}", { "label": "Duración Analizar Preferencias", "yAxis": "left" }],
            # Puedes añadir más Lambdas aquí
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "Duración de Ejecución de Lambdas (indicador de uso de recursos)"
          period      = 300
          stat        = "Average"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      # Widget 3: Conexiones a la base de datos (Métrica RDS)
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "Conexiones RDS" }],
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "CPU RDS" }]
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "Manejo de Conexiones y CPU de RDS"
          period      = 300
          stat        = "Average"
        }
      },
      # Widget 4: Logs de Errores (de Logs Insights - basado en logs estructurados)
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          query = <<-EOT
            fields @timestamp, functionName, level, errorMessage, orderId
            | filter level = 'ERROR'
            | sort @timestamp desc
            | limit 20
          EOT
          region      = var.aws_region
          stacked     = false
          title       = "Logs de Errores Recientes"
          view        = "table"
          # Puedes especificar los log groups aquí, o Logs Insights los inferirá si la query es global
          # logGroupNames = ["/aws/lambda/reyGasExpress-processOrder-${var.environment}", "/aws/lambda/reyGasExpress-analyzePreferences-${var.environment}"]
        }
      },
      # Widget 5: Resumen de Operaciones REST/CRUD (de Logs Insights - basado en logs estructurados)
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          query = <<-EOT
            fields @timestamp, functionName, message, operationType, httpMethod, orderId, customerName, dbStatus, eventBusStatus
            | filter operationType = 'CREATE' or httpMethod = 'POST' or httpMethod = 'GET' or httpMethod = 'PUT' or httpMethod = 'DELETE'
            | sort @timestamp desc
            | limit 50
          EOT
          region      = var.aws_region
          stacked     = false
          title       = "Actividad Reciente (GET/POST/CRUD)"
          view        = "table"
          # logGroupNames = ["/aws/lambda/reyGasExpress-processOrder-${var.environment}", "/aws/lambda/reyGasExpress-analyzePreferences-${var.environment}"]
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}