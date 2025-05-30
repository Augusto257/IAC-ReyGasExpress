# Variables de entrada para WAF

variable "waf_name" {
  description = "Nombre del WAF para ReyGasExpress"
  type        = string
  default     = "reyGasExpress-web-acl"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "rate_limit" {
  description = "Límite de requests por IP"
  type        = number
  default     = 2000
}