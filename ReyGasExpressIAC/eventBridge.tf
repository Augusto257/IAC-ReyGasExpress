# Define el EventBridge Bus que utilizará la Lambda processOrder para enviar eventos.
resource "aws_cloudwatch_event_bus" "reyGasExpress_event_bus" {
  name = "${var.event_bus_name}-${var.environment}"

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}