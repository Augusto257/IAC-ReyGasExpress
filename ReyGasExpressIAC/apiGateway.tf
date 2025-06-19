# Crea la API HTTP  para conectar a la función "Registrar datos de pedido"
resource "aws_apigatewayv2_api" "reyGasExpress_api" {
  name          = "reyGasExpress-api-${var.environment}"
  protocol_type = "HTTP"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Integración para register_order_lambda
resource "aws_apigatewayv2_integration" "register_order_lambda_integration" {
  api_id               = aws_apigatewayv2_api.reyGasExpress_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.register_order_lambda.invoke_arn
  timeout_milliseconds = 29000
}

# Integración para process_order_lambda
resource "aws_apigatewayv2_integration" "process_order_lambda_integration" {
  api_id               = aws_apigatewayv2_api.reyGasExpress_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.process_order_lambda.invoke_arn
  timeout_milliseconds = 29000
}

# Integración para analyze_preferences_lambda
resource "aws_apigatewayv2_integration" "analyze_preferences_lambda_integration" {
  api_id               = aws_apigatewayv2_api.reyGasExpress_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.analyze_preferences_lambda.invoke_arn
  timeout_milliseconds = 29000
}

# Integración para generate_report_lambda
resource "aws_apigatewayv2_integration" "generate_report_lambda_integration" {
  api_id               = aws_apigatewayv2_api.reyGasExpress_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.generate_report_lambda.invoke_arn
  timeout_milliseconds = 29000
}

# Integración para send_email_report_lambda
resource "aws_apigatewayv2_integration" "send_email_report_lambda_integration" {
  api_id               = aws_apigatewayv2_api.reyGasExpress_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.send_email_report_lambda.invoke_arn
  timeout_milliseconds = 29000
}

# Configuración de rutas para cada Lambda
resource "aws_apigatewayv2_route" "register_order_route" {
  api_id             = aws_apigatewayv2_api.reyGasExpress_api.id
  route_key          = "POST /orders"
  target             = "integrations/${aws_apigatewayv2_integration.register_order_lambda_integration.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_route" "process_order_route" {
  api_id             = aws_apigatewayv2_api.reyGasExpress_api.id
  route_key          = "POST /process-orders"
  target             = "integrations/${aws_apigatewayv2_integration.process_order_lambda_integration.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_route" "analyze_preferences_route" {
  api_id             = aws_apigatewayv2_api.reyGasExpress_api.id
  route_key          = "POST /analyze-preferences"
  target             = "integrations/${aws_apigatewayv2_integration.analyze_preferences_lambda_integration.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_route" "generate_report_route" {
  api_id             = aws_apigatewayv2_api.reyGasExpress_api.id
  route_key          = "POST /generate-report"
  target             = "integrations/${aws_apigatewayv2_integration.generate_report_lambda_integration.id}"
  authorization_type = "AWS_IAM"
}

resource "aws_apigatewayv2_route" "send_email_report_route" {
  api_id             = aws_apigatewayv2_api.reyGasExpress_api.id
  route_key          = "POST /send-email-report"
  target             = "integrations/${aws_apigatewayv2_integration.send_email_report_lambda_integration.id}"
  authorization_type = "AWS_IAM"
}

# Configuración de balanceo de carga 70-30 entre dos stages
resource "aws_apigatewayv2_stage" "primary_stage" {
  api_id        = aws_apigatewayv2_api.reyGasExpress_api.id
  name          = "v1"
  deployment_id = aws_apigatewayv2_deployment.api_deployment.id
  auto_deploy   = true

  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }

  tags = {
    Environment   = var.environment
    Application   = "reyGasExpress"
    TrafficWeight = "70"
  }
}

resource "aws_apigatewayv2_stage" "secondary_stage" {
  api_id        = aws_apigatewayv2_api.reyGasExpress_api.id
  name          = "v2"
  deployment_id = aws_apigatewayv2_deployment.api_deployment.id
  auto_deploy   = true

  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }

  tags = {
    Environment   = var.environment
    Application   = "reyGasExpress"
    TrafficWeight = "30"
  }
}


# Crea un despligue de la API
resource "aws_apigatewayv2_deployment" "api_deployment" {
  api_id = aws_apigatewayv2_api.reyGasExpress_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_route.register_order_route.id,
      aws_apigatewayv2_route.process_order_route.id,
      aws_apigatewayv2_route.analyze_preferences_route.id,
      aws_apigatewayv2_route.generate_report_route.id,
      aws_apigatewayv2_route.send_email_report_route.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Crea una etapa de la API
resource "aws_apigatewayv2_stage" "reyGasExpress_stage" {
  api_id        = aws_apigatewayv2_api.reyGasExpress_api.id
  name          = var.api_stage_name
  deployment_id = aws_apigatewayv2_deployment.api_deployment.id
  auto_deploy   = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format = jsonencode({
      requestId          = "$context.requestId",
      ip                 = "$context.identity.sourceIp",
      requestTime        = "$context.requestTime",
      httpMethod         = "$context.httpMethod",
      path               = "$context.path",
      status             = "$context.status",
      protocol           = "$context.protocol",
      responseLength     = "$context.responseLength",
      integrationLatency = "$context.integration.latency",
      integrationStatus  = "$context.integration.status"
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
  source_arn    = "${aws_apigatewayv2_api.reyGasExpress_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigateway_invoke_process_order_lambda" {
  statement_id  = "AllowAPIGatewayInvokeProcessOrderLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_order_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.reyGasExpress_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigateway_invoke_analyze_preferences_lambda" {
  statement_id  = "AllowAPIGatewayInvokeAnalyzePreferencesLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyze_preferences_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.reyGasExpress_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigateway_invoke_generate_report_lambda" {
  statement_id  = "AllowAPIGatewayInvokeGenerateReportLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_report_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.reyGasExpress_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigateway_invoke_send_email_report_lambda" {
  statement_id  = "AllowAPIGatewayInvokeSendEmailReportLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_email_report_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.reyGasExpress_api.execution_arn}/*/*"
}

resource "aws_kms_key" "cloudwatch_logs_encryption" {
  description             = "KMS key for encrypting CloudWatch logs"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-policy",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cloudwatch_logs_alias" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs_encryption.key_id
}

# Crea un grupo de logs en Cloudwatch
resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.reyGasExpress_api.name}/${var.api_stage_name}"
  retention_in_days = 365

  kms_key_id = aws_kms_key.cloudwatch_logs_encryption.arn

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}