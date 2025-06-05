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

# Política consolidada para todos los permisos que las funciones Lambda necesitan
# Esta política incluye permisos para CloudWatch Logs, SQS, DynamoDB, EventBridge, S3, y SNS/SES.
resource "aws_iam_policy" "lambda_all_permissions_policy" {
  name        = "reyGasExpress-lambda-all-permissions-policy-${var.environment}"
  description = "Política consolidada para todos los permisos que las funciones Lambda de reyGasExpress necesitan."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Permisos para CloudWatch Logs (Esenciales para la ejecución de Lambda)
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*"
      },
      # Permisos para SQS: Enviar mensajes (registerOrder Lambda)
      {
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ],
        Effect   = "Allow",
        Resource = aws_sqs_queue.reyGasExpress_order_queue.arn
      },
      # Permisos para SQS: Recibir y eliminar mensajes (processOrder Lambda)
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect   = "Allow",
        Resource = aws_sqs_queue.reyGasExpress_order_queue.arn
      },
      # Permisos para DynamoDB: Escribir elementos (processOrder Lambda)
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.reyGasExpress_orders_table.arn
      },
      # Permisos para DynamoDB: Leer elementos (analyzePreferences, generateReport Lambdas)
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = [
          aws_dynamodb_table.reyGasExpress_orders_table.arn,
          "${aws_dynamodb_table.reyGasExpress_orders_table.arn}/index/*" # Para acceder a GSIs
        ]
      },
      # Permisos para EventBridge: Enviar eventos (processOrder Lambda)
      {
        Action   = "events:PutEvents",
        Effect   = "Allow",
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}-${var.environment}"
      },
      # Permisos para S3: Escribir objetos en el bucket de reportes (generateReport Lambda)
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_reports_bucket.arn}/*"
      },
      # Permisos para S3: Leer objetos del bucket de análisis (analyzePreferences Lambda)
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_analysis_bucket.arn}/*"
      },
      # Permisos para S3: Escribir objetos en el bucket de análisis (analyzePreferences Lambda)
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_analysis_bucket.arn}/*"
      },
      # Permisos para S3: Leer objetos del bucket de reportes (sendEmailReport Lambda)
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_reports_bucket.arn}/*"
      },
      # Permisos para SNS: Publicar mensajes en el tópico de reportes (analyzePreferences Lambda)
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.reyGasExpress_reports_topic.arn
      },
      # Permisos para SNS: Publicar mensajes en el tópico de emails (generateReport Lambda)
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.reyGasExpress_email_topic.arn
      },
      # Permisos para SES: Enviar correos electrónicos (sendEmailReport Lambda)
      {
        Action   = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail"
        ],
        Effect   = "Allow",
        Resource = "*" # Permite enviar desde cualquier identidad verificada
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}

# Adjunta la política consolidada de permisos al rol de ejecución de Lambda
resource "aws_iam_role_policy_attachment" "lambda_all_permissions_attachment" {
  role        = aws_iam_role.lambda_execution_role.name
  policy_arn  = aws_iam_policy.lambda_all_permissions_policy.arn
}