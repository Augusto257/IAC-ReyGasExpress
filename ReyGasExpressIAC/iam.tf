data "aws_caller_identity" "current" {}

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
      # Permisos para CloudWatch Metrics (utilizado por registerOrder)
      {
        Action = [
          "cloudwatch:PutMetricData"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      # Permisos para EventBridge: Enviar eventos
      {
        Action   = "events:PutEvents",
        Effect   = "Allow",
        Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}-${var.environment}"
      },
      # Permisos para S3: Escribir objetos en el bucket de reportes y análisis
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = [
            "${aws_s3_bucket.reyGasExpress_reports_bucket.arn}/*",
            "${aws_s3_bucket.reyGasExpress_analysis_bucket.arn}/*"
        ]
      },
      # Permisos para S3: Leer objetos de los buckets de análisis y reportes
      {
        Action   = ["s3:GetObject"],
        Effect   = "Allow",
        Resource = [
            "${aws_s3_bucket.reyGasExpress_analysis_bucket.arn}/*",
            "${aws_s3_bucket.reyGasExpress_reports_bucket.arn}/*"
        ]
      },
      # Permisos para SNS: Publicar mensajes en el tópico de reportes y emails
      {
        Action   = "sns:Publish",
        Effect   = "Allow",
        Resource = [
            aws_sns_topic.reyGasExpress_reports_topic.arn,
            aws_sns_topic.reyGasExpress_email_topic.arn
        ]
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
      },
      # NUEVOS PERMISOS PARA SECRETS MANAGER (Acceso a la contraseña de RDS)
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_master_password.arn
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

# Adjunta la política de acceso a la VPC al rol de ejecución de Lambda
# Este es CRUCIAL para que las Lambdas puedan conectarse a recursos dentro de la VPC (como RDS).
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


# Rol para CloudFront
resource "aws_iam_role" "cloudfront_s3_access_role" {
  name_prefix = "cloudfront-s3-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
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

resource "aws_iam_role_policy" "cloudfront_s3_read_policy" {
  name = "cloudfront-s3-read-policy"
  role = aws_iam_role.cloudfront_s3_access_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.reygas_frontend_bucket.arn,
          "${aws_s3_bucket.reygas_frontend_bucket.arn}/*",
          aws_s3_bucket.reygas_frontend_failover_bucket.arn,
          "${aws_s3_bucket.reygas_frontend_failover_bucket.arn}/*"
        ]
      }
    ]
  })
}