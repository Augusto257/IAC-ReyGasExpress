resource "aws_cloudwatch_dashboard" "reygas_express_dashboard" {
  dashboard_name = "ReyGasExpress-Application-Overview-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      # Bloque 1: Título y Visión General del Sistema
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "#Visión general de pedidos de ReyGasExpress\n\nEste dashboard monitorea el rendimiento y la salud de las Lambdas y RDS PostgreSQL en el entorno `${var.environment}`."
        }
      },
      # Bloque 2: Métricas Clave de AWS Lambda (Visión General)
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.register_order_lambda.function_name, { "label": "Register Order Invocations" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.process_order_lambda.function_name, { "label": "Process Order Invocations" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.analyze_preferences_lambda.function_name, { "label": "Analyze Preferences Invocations" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.generate_report_lambda.function_name, { "label": "Generate Report Invocations" }],
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.send_email_report_lambda.function_name, { "label": "Send Email Report Invocations" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda: Invocaciones Totales"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 8
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.register_order_lambda.function_name, { "label": "Register Order Errors" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.process_order_lambda.function_name, { "label": "Process Order Errors" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.analyze_preferences_lambda.function_name, { "label": "Analyze Preferences Errors" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.generate_report_lambda.function_name, { "label": "Generate Report Errors" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.send_email_report_lambda.function_name, { "label": "Send Email Report Errors" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda: Errores Totales"
          period  = 300
          stat    = "Sum"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 8
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.register_order_lambda.function_name, { "label": "Register Order", "stat": "Average" }],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.process_order_lambda.function_name, { "label": "Process Order", "stat": "Average" }],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.analyze_preferences_lambda.function_name, { "label": "Analyze Preferences", "stat": "Average" }],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.generate_report_lambda.function_name, { "label": "Generate Report", "stat": "Average" }],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.send_email_report_lambda.function_name, { "label": "Send Email Report", "stat": "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda: Duración Promedio (ms)"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },

      # Bloque 3: Métricas Clave de RDS PostgreSQL
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "CPU Utilization (%)", "stat": "Average" }],
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "Memoria Libre (Bytes)", "stat": "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS: Uso de CPU y Memoria Libre"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "Conexiones a BD", "stat": "Average" }],
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "Read IOPS", "yAxis": "right" }],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", aws_db_instance.reygas_postgres_db.identifier, { "label": "Write IOPS", "yAxis": "right" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS: Conexiones y Operaciones de E/S"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}