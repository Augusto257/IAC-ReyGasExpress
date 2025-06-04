# Tabla DynamoDB para almacenar los pedidos procesados
resource "aws_dynamodb_table" "reyGasExpress_orders_table" {
  name             = "reyGasExpress-orders-table-${var.environment}"
  billing_mode     = "PAY_PER_REQUEST"

  # Clave primaria (Partition Key)
  hash_key         = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}