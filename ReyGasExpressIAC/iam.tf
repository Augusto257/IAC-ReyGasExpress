# Permite a las funciones Lambda asumir una identidad en AWS para ejecutar su código
# y acceder a otros servicios de AWS de forma segura
resource "aws_iam_role" "lambda_execution_role" {
  name = var.lambda_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política gestionada de AWS para la ejecución básica de Lambda
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Asigna una política de permisos a un rol de IAM
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Política para permitir a lambda enviar mensajes SQS
resource "aws_iam_policy" "lambda_sqs_send_policy" {
  name        = "reyGasExpress-lambda-sqs-send-policy-${var.environment}"
  description = "Permite a Lambda enviar mensajes a la cola de pedidos SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"   
        ],
        Effect   = "Allow",
        Resource = aws_sqs_queue.reyGasExpress_order_queue.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Política de SQS al rol de ejecución de lamba
resource "aws_iam_role_policy_attachment" "lambda_sqs_send_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sqs_send_policy.arn
}

# Política para permitir a Lambda escribir en la tabla DynamoDB de pedidos
resource "aws_iam_policy" "lambda_dynamodb_write_policy" {
  name        = "reyGasExpress-lambda-dynamodb-write-policy-${var.environment}"
  description = "Permite a Lambda escribir elementos en la tabla DynamoDB de pedidos"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.reyGasExpress_orders_table.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política de escritura de DynamoDB al rol de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_write_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_write_policy.arn
}

# Política para permitir a Lambda enviar eventos a EventBridge
resource "aws_iam_policy" "lambda_eventbridge_put_events_policy" {
  name        = "reyGasExpress-lambda-eventbridge-put-events-policy-${var.environment}"
  description = "Permite a Lambda enviar eventos a EventBridge"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "events:PutEvents",
        Effect   = "Allow",
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}-${var.environment}"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política de EventBridge al rol de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_eventbridge_put_events_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_eventbridge_put_events_policy.arn
}

# Política para permitir a Lambda consumir mensajes de la cola SQS
resource "aws_iam_policy" "lambda_sqs_receive_policy" {
  name        = "reyGasExpress-lambda-sqs-receive-policy-${var.environment}"
  description = "Permite a Lambda recibir y eliminar mensajes de la cola de pedidos SQS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect   = "Allow",
        Resource = aws_sqs_queue.reyGasExpress_order_queue.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política de recepción de SQS al rol de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_sqs_receive_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sqs_receive_policy.arn
}

# Política para permitir a Lambda leer datos de la tabla DynamoDB de pedidos (y su índice)
resource "aws_iam_policy" "lambda_dynamodb_read_policy" {
  name        = "reyGasExpress-lambda-dynamodb-read-policy-${var.environment}"
  description = "Permite a Lambda leer elementos de la tabla DynamoDB de pedidos y su índice."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        # Necesita permisos sobre la tabla principal y el GSI
        Resource = [
          aws_dynamodb_table.reyGasExpress_orders_table.arn,
          "${aws_dynamodb_table.reyGasExpress_orders_table.arn}/index/*"
        ]
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política de lectura de DynamoDB al rol de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_read_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_read_policy.arn
}

# Política para permitir a Lambda publicar mensajes en el tópico SNS de reportes
resource "aws_iam_policy" "lambda_sns_publish_policy" {
  name        = "reyGasExpress-lambda-sns-publish-policy-${var.environment}"
  description = "Permite a Lambda publicar mensajes en el tópico SNS de reportes."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.reyGasExpress_reports_topic.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política de SNS publish al rol de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_sns_publish_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sns_publish_policy.arn
}