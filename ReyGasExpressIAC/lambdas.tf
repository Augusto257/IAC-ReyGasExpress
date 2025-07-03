# Crea la función Lambda para "Registrar datos de pedido"
resource "aws_lambda_function" "register_order_lambda" {
  function_name = "reyGasExpress-registerOrder-${var.environment}"
  handler       = "registerOrder.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename         = "${var.lambda_code_path}/registerOrder.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/registerOrder.zip")

  timeout     = 10
  memory_size = 512

  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }

  publish = true
}

# Crea la función Lambda para "Procesar y almacenar pedidos"
resource "aws_lambda_function" "process_order_lambda" {
  function_name = "reyGasExpress-processOrder-${var.environment}"
  handler       = "processOrder.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename         = "${var.lambda_code_path}/processOrder.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/processOrder.zip")

  timeout     = 60
  memory_size = 256

  # Configuración de VPC para acceder a RDS
  vpc_config {
    subnet_ids         = [aws_subnet.lambda_subnet_1.id, aws_subnet.lambda_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      EVENT_BUS_NAME           = "${var.event_bus_name}-${var.environment}"
      # Variables para la conexión a RDS PostgreSQL
      DB_HOST                  = aws_db_instance.reygas_postgres_db.address
      DB_PORT                  = aws_db_instance.reygas_postgres_db.port
      DB_NAME                  = var.db_name
      DB_USERNAME              = var.db_username
      DB_PASSWORD_SECRET_ARN   = aws_secretsmanager_secret.db_master_password.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Crea la función Lambda para "Analizar Preferencias"
resource "aws_lambda_function" "analyze_preferences_lambda" {
  function_name = "reyGasExpress-analyzePreferences-${var.environment}"
  handler       = "analyzePreferences.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename         = "${var.lambda_code_path}/analyzePreferences.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/analyzePreferences.zip")

  timeout     = 90
  memory_size = 256

  # Configuración de VPC para acceder a RDS
  vpc_config {
    subnet_ids         = [aws_subnet.lambda_subnet_1.id, aws_subnet.lambda_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      ANALYSIS_BUCKET_NAME = aws_s3_bucket.reyGasExpress_analysis_bucket.id
      REPORT_TOPIC_ARN     = aws_sns_topic.reyGasExpress_reports_topic.arn
      # Variables para la conexión a RDS PostgreSQL
      DB_HOST                  = aws_db_instance.reygas_postgres_db.address
      DB_PORT                  = aws_db_instance.reygas_postgres_db.port
      DB_NAME                  = var.db_name
      DB_USERNAME              = var.db_username
      DB_PASSWORD_SECRET_ARN   = aws_secretsmanager_secret.db_master_password.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Crea la función Lambda para "Generar Documento de Reporte de preferencias"
resource "aws_lambda_function" "generate_report_lambda" {
  function_name = "reyGasExpress-generateReport-${var.environment}"
  handler       = "generateReport.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn

  filename         = "${var.lambda_code_path}/generateReport.zip"
  source_code_hash = filebase64sha256("${var.lambda_code_path}/generateReport.zip")

  timeout     = 90
  memory_size = 256

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
  memory_size = 192

  environment {
    variables = {
      REPORTS_BUCKET_NAME = aws_s3_bucket.reyGasExpress_reports_bucket.id
      FROM_EMAIL          = var.from_email_address
      TO_EMAIL            = var.to_email_address
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
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