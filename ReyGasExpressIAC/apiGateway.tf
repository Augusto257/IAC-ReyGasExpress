# Crea la API HTTP  para conectar a la función "Registrar datos de pedido"
resource "aws_apigatewayv2_api" "reyGasExpress_api" {
  name          = "reyGasExpress-api-${var.environment}"
  protocol_type = "HTTP" # Es una API HTTP
  target        = aws_lambda_function.register_order_lambda.invoke_arn

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Se define la integración que conecta el ApiGateway con la función "Registrar datos de pedido"
# para manejar solicitudes POST
resource "aws_apigatewayv2_integration" "register_order_lambda_integration" {
  api_id             = aws_apigatewayv2_api.reyGasExpress_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.register_order_lambda.invoke_arn
  timeout_milliseconds = 29000
}

# Configura la ruta POST /orders en la API
resource "aws_apigatewayv2_route" "register_order_route" {
  api_id    = aws_apigatewayv2_api.reyGasExpress_api.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.register_order_lambda_integration.id}"
}

# Crea un despligue de la API
resource "aws_apigatewayv2_deployment" "api_deployment" {
  api_id = aws_apigatewayv2_api.reyGasExpress_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_route.register_order_route.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Crea una etapa de la API
resource "aws_apigatewayv2_stage" "reyGasExpress_stage" {
  api_id      = aws_apigatewayv2_api.reyGasExpress_api.id
  name        = var.api_stage_name
  deployment_id = aws_apigatewayv2_deployment.api_deployment.id
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format          = jsonencode({
      requestId               = "$context.requestId",
      ip                      = "$context.identity.sourceIp",
      requestTime             = "$context.requestTime",
      httpMethod              = "$context.httpMethod",
      path                    = "$context.path",
      status                  = "$context.status",
      protocol                = "$context.protocol",
      responseLength          = "$context.responseLength",
      integrationLatency      = "$context.integration.latency",
      integrationStatus       = "$context.integration.status"
    })
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Otorga permisos necesarios para invocar la función "Registrar datos de pedido"
resource "aws_lambda_permission" "allow_apigateway_invoke_register_order_lambda" {
  statement_id  = "AllowAPIGatewayInvokeRegisterOrderLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_order_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.reyGasExpress_api.execution_arn}/*/*"
}

# Crea un grupo de logs en Cloudwatch
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.reyGasExpress_api.name}/${var.api_stage_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}