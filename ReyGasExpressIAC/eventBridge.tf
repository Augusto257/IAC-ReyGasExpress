resource "aws_cloudwatch_event_bus" "reygas_orders_event_bus" {
  name = "${var.event_bus_name}-${var.environment}" 

  tags = {
    Name        = "ReyGasExpress-Orders-EventBus-${var.environment}"
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_rule" "analyze_preferences_rule" {
  name        = "reyGasExpress-analyzePreferences-rule-${var.environment}"
  description = "Captura eventos de pedidos procesados para análisis de preferencias."
  # Asegúrate de que este 'event_bus_name' apunte al bus definido arriba
  event_bus_name = aws_cloudwatch_event_bus.reygas_orders_event_bus.name

  event_pattern = jsonencode({
    source        = ["orders.system"],
    "detail-type" = ["Order Processed"]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_target" "analyze_preferences_lambda_target" {
  rule           = aws_cloudwatch_event_rule.analyze_preferences_rule.name
  arn            = aws_lambda_function.analyze_preferences_lambda.arn
  # Asegúrate de que este 'event_bus_name' apunte al bus definido arriba
  event_bus_name = aws_cloudwatch_event_bus.reygas_orders_event_bus.name
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_analyze_preferences_lambda" {
  statement_id  = "AllowEventBridgeInvokeAnalyzePreferences"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyze_preferences_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.analyze_preferences_rule.arn
}