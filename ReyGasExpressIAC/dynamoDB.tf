# Tabla DynamoDB para almacenar los pedidos procesados
resource "aws_dynamodb_table" "reyGasExpress_orders_table" {
  name             = "reyGasExpress-orders-table-${var.environment}"
  billing_mode     = "PAY_PER_REQUEST"

  hash_key         = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name               = "customer-index"
    hash_key           = "customerId"
    projection_type    = "ALL"
    # Si usas PAY_PER_REQUEST, no necesitas provision_throughput
    # read_capacity = 1
    # write_capacity = 1
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {  
    enabled = true
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}