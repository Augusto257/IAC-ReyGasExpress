# Variables de salida para WAF

output "waf_web_acl_id" {
  description = "ID del WAF Web ACL"
  value       = aws_wafv2_web_acl.reyGasExpress_waf.id
}

output "waf_web_acl_arn" {
  description = "ARN del WAF Web ACL"
  value       = aws_wafv2_web_acl.reyGasExpress_waf.arn
}