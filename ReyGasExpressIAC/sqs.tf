# Crea la cola principal para recibir y procesar los mensajes de pedidos
resource "aws_sqs_queue" "reyGasExpress_order_queue" {
  name                      = "reyGasExpress-order-queue-${var.environment}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Crea la cola de mensajes fallidos
resource "aws_sqs_queue" "reyGasExpress_order_dlq" {
  name                      = "reyGasExpress-order-dlq-${var.environment}"
  message_retention_seconds = 1209600
  max_message_size          = 262144

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Configura la política de redrive para que los mensajes de la cola principal 
# que fallen 5 veces sean enviados automáticamente a la DLQ.
resource "aws_sqs_queue_redrive_policy" "reyGasExpress_order_queue_redrive" {
  queue_url    = aws_sqs_queue.reyGasExpress_order_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reyGasExpress_order_dlq.arn
    maxReceiveCount     = 5
  })
}