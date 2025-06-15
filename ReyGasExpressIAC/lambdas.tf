# Crea la función Lambda para "Registrar datos de pedido"
resource "aws_lambda_function" "register_order_lambda" {
  function_name = "reyGasExpress-registerOrder-${var.environment}"
  handler       = "registerOrder.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename      = "${var.lambda_code_path}/registerOrder.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/registerOrder.zip")

  timeout       = 30
  memory_size   = 128 

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.reyGasExpress_order_queue.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids         
    security_group_ids = var.lambda_security_group_ids 
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.reyGasExpress_dlq.arn
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Crea la función Lambda para "Procesar y almacenar pedidos"
resource "aws_lambda_function" "process_order_lambda" {
  function_name = "reyGasExpress-processOrder-${var.environment}"
  handler       = "processOrder.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  # Ruta al archivo ZIP con tu código para processOrder
  filename      = "${var.lambda_code_path}/processOrder.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/processOrder.zip")

  timeout       = 60
  memory_size   = 256

  # Variables de entorno para la Lambda
  environment {
    variables = {
      ORDERS_TABLE_NAME = aws_dynamodb_table.reyGasExpress_orders_table.name
      EVENT_BUS_NAME    = "${var.event_bus_name}-${var.environment}"
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids         
    security_group_ids = var.lambda_security_group_ids 
  }
  
  dead_letter_config {
    target_arn = aws_sqs_queue.reyGasExpress_dlq.arn
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Configura el SQS Event Source Mapping para invocar la Lambda processOrder
resource "aws_lambda_event_source_mapping" "process_order_sqs_trigger" {
  event_source_arn = aws_sqs_queue.reyGasExpress_order_queue.arn
  function_name    = aws_lambda_function.process_order_lambda.arn
  batch_size       = 10
  enabled          = true
}

# Crea la función Lambda para "Analizar Preferencias"
resource "aws_lambda_function" "analyze_preferences_lambda" {
  function_name = "reyGasExpress-analyzePreferences-${var.environment}"
  handler       = "analyzePreferences.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename      = "${var.lambda_code_path}/analyzePreferences.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/analyzePreferences.zip")

  timeout       = 90 
  memory_size   = 256

  environment {
    variables = {
      ORDERS_TABLE_NAME    = aws_dynamodb_table.reyGasExpress_orders_table.name
      ANALYSIS_BUCKET_NAME = aws_s3_bucket.reyGasExpress_analysis_bucket.id
      REPORT_TOPIC_ARN     = aws_sns_topic.reyGasExpress_reports_topic.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids         
    security_group_ids = var.lambda_security_group_ids 
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.reyGasExpress_dlq.arn
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# EventBridge Rule para invocar la Lambda analyzePreferences cuando se procesa un pedido
resource "aws_cloudwatch_event_rule" "analyze_preferences_rule" {
  name          = "reyGasExpress-analyzePreferences-rule-${var.environment}"
  description   = "Captura eventos de pedidos procesados para análisis de preferencias."
  event_bus_name = aws_cloudwatch_event_bus.reyGasExpress_event_bus.name

  event_pattern = jsonencode({
    source     = ["orders.system"],
    "detail-type" = ["Order Processed"]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Permiso para que EventBridge invoque la Lambda analyzePreferences
resource "aws_lambda_permission" "allow_eventbridge_invoke_analyze_preferences_lambda" {
  statement_id  = "AllowEventBridgeInvokeAnalyzePreferences"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyze_preferences_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.analyze_preferences_rule.arn
}

# Target para la EventBridge Rule: la Lambda analyzePreferences
resource "aws_cloudwatch_event_target" "analyze_preferences_lambda_target" {
  rule      = aws_cloudwatch_event_rule.analyze_preferences_rule.name
  arn       = aws_lambda_function.analyze_preferences_lambda.arn
  event_bus_name = aws_cloudwatch_event_bus.reyGasExpress_event_bus.name # Nuestro EventBus personalizado
}

# Crea la función Lambda para "Generar Documento de Reporte de preferencias"
resource "aws_lambda_function" "generate_report_lambda" {
  function_name = "reyGasExpress-generateReport-${var.environment}"
  handler       = "generateReport.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename      = "${var.lambda_code_path}/generateReport.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/generateReport.zip")

  timeout       = 90
  memory_size   = 256

  environment {
    variables = {
      ANALYSIS_BUCKET_NAME = aws_s3_bucket.reyGasExpress_analysis_bucket.id
      REPORTS_BUCKET_NAME  = aws_s3_bucket.reyGasExpress_reports_bucket.id
      EMAIL_TOPIC_ARN      = aws_sns_topic.reyGasExpress_email_topic.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids         
    security_group_ids = var.lambda_security_group_ids 
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Configura la suscripción de la Lambda generateReport al tópico SNS de reportes
resource "aws_sns_topic_subscription" "generate_report_lambda_sns_subscription" {
  topic_arn = aws_sns_topic.reyGasExpress_reports_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.generate_report_lambda.arn
}

# Crea la función Lambda para "Enviar Reporte por correo"
resource "aws_lambda_function" "send_email_report_lambda" {
  function_name = "reyGasExpress-sendEmailReport-${var.environment}"
  handler       = "sendEmailReport.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename         = "${var.lambda_code_path}/sendEmailReport.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/sendEmailReport.zip")

  timeout     = 60
  memory_size = 192 # Un poco más de memoria si el reporte es grande

  environment {
    variables = {
      REPORTS_BUCKET_NAME = aws_s3_bucket.reyGasExpress_reports_bucket.id
      FROM_EMAIL          = var.from_email_address
      TO_EMAIL            = var.to_email_address # Valor por defecto, puede ser sobrescrito por el payload SNS
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids         
    security_group_ids = var.lambda_security_group_ids 
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue" "reyGasExpress_dlq" {
  name = "reyGasExpress-registerOrder-dlq-${var.environment}"
  
  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
  }
}

# Configura la suscripción de la Lambda sendEmailReport al tópico SNS de email
resource "aws_sns_topic_subscription" "send_email_report_lambda_sns_subscription" {
  topic_arn = aws_sns_topic.reyGasExpress_email_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_email_report_lambda.arn
}

# Permiso para que SNS invoque la Lambda sendEmailReport
resource "aws_lambda_permission" "allow_sns_invoke_send_email_report_lambda" {
  statement_id  = "AllowSNSInvokeSendEmailReport"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_email_report_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.reyGasExpress_email_topic.arn
}