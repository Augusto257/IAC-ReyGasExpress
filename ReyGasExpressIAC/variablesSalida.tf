# Variables de salida para WAF

output "waf_web_acl_id" {
  description = "ID del WAF Web ACL"
  value       = aws_wafv2_web_acl.reyGasExpress_waf.id
}

output "waf_web_acl_arn" {
  description = "ARN del WAF Web ACL"
  value       = aws_wafv2_web_acl.reyGasExpress_waf.arn
}

#Variables de salida para CLOUDFRONT

output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribución CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.arn
}

output "cloudfront_domain_name" {
  description = "Nombre de dominio de CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted Zone ID de CloudFront"
  value       = aws_cloudfront_distribution.reygas_distribution.hosted_zone_id
}