resource "aws_cloudwatch_dashboard" "reygas_express_dashboard" {
  dashboard_name = "ReyGasExpress-Dashboard-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            # Invocaciones de todas tus Lambdas
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.register_order_lambda.function_name, { "label": "Register Order Invocations" } ],
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.process_order_lambda.function_name, { "label": "Process Order Invocations" } ],
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.analyze_preferences_lambda.function_name, { "label": "Analyze Preferences Invocations" } ],
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.generate_report_lambda.function_name, { "label": "Generate Report Invocations" } ],
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.send_email_report_lambda.function_name, { "label": "Send Email Report Invocations" } ]
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "Lambda Invocations"
          period      = 300 # 5 minutos
          stat        = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.register_order_lambda.function_name, { "label": "Register Order Errors" } ],
            [ "AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.process_order_lambda.function_name, { "label": "Process Order Errors" } ],
            [ "AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.analyze_preferences_lambda.function_name, { "label": "Analyze Preferences Errors" } ],
            [ "AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.generate_report_lambda.function_name, { "label": "Generate Report Errors" } ],
            [ "AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.send_email_report_lambda.function_name, { "label": "Send Email Report Errors" } ]
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "Lambda Errors"
          period      = 300
          stat        = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApiGateway", "Latency", "ApiName", aws_apigatewayv2_api.reyGasExpress_api.name, "Stage", aws_apigatewayv2_stage.primary_stage.name, { "label": "API Gateway Latency (Primary)" } ],
            [ "AWS/ApiGateway", "Latency", "ApiName", aws_apigatewayv2_api.reyGasExpress_api.name, "Stage", aws_apigatewayv2_stage.secondary_stage.name, { "label": "API Gateway Latency (Secondary)" } ]
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "API Gateway Latency"
          period      = 300
          stat        = "Average"
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
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "AWS/ApiGateway", "5XXError", "ApiName", aws_apigatewayv2_api.reyGasExpress_api.name, "Stage", aws_apigatewayv2_stage.primary_stage.name, { "label": "API Gateway 5XX Errors (Primary)" } ],
            [ "AWS/ApiGateway", "5XXError", "ApiName", aws_apigatewayv2_api.reyGasExpress_api.name, "Stage", aws_apigatewayv2_stage.secondary_stage.name, { "label": "API Gateway 5XX Errors (Secondary)" } ]
          ]
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "API Gateway 5XX Errors"
          period      = 300
          stat        = "Sum"
        }
      }
    ]
  })
}