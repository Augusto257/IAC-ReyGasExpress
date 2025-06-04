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

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# lambdas.tf (Añadir al final del archivo)

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