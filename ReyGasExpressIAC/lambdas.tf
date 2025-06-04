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