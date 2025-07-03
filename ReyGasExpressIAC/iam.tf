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
resource "aws_iam_policy" "lambda_all_permissions_policy" {
  name        = "reyGasExpress-lambda-all-permissions-policy-${var.environment}"
  description = "Política consolidada para todos los permisos que las funciones Lambda de reyGasExpress necesitan."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Permisos para CloudWatch Logs
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      # Permisos para DynamoDB: Escribir elementos
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.reyGasExpress_orders_table.arn
      },
      # Permisos para DynamoDB: Leer elementos 
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Effect = "Allow",
        Resource = [
          aws_dynamodb_table.reyGasExpress_orders_table.arn,
          "${aws_dynamodb_table.reyGasExpress_orders_table.arn}/index/*"
        ]
      },
      # Permisos para EventBridge: Enviar eventos
      {
        Action   = "events:PutEvents",
        Effect   = "Allow",
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}-${var.environment}"
      },
      # Permisos para S3: Escribir objetos en el bucket de reportes
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_reports_bucket.arn}/*"
      },
      # Permisos para S3: Leer objetos del bucket de análisis
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_analysis_bucket.arn}/*"
      },
      # Permisos para S3: Escribir objetos en el bucket de análisis
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_analysis_bucket.arn}/*"
      },
      # Permisos para S3: Leer objetos del bucket de reportes
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.reyGasExpress_reports_bucket.arn}/*"
      },
      # Permisos para SNS: Publicar mensajes en el tópico de reportes
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.reyGasExpress_reports_topic.arn
      },
      # Permisos para SNS: Publicar mensajes en el tópico de emails
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = aws_sns_topic.reyGasExpress_email_topic.arn
      },
      # Permisos para SES: Enviar correos electrónicos
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail"
        ],
        Effect   = "Allow",
        Resource = "*"
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
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_all_permissions_policy.arn
}

# En tu archivo iam.tf, asegúrate que el rol tenga estas políticas:
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
