# Configura nuestro firewall de aplicaciones web que protege de ataques web
resource "aws_wafv2_web_acl" "reyGasExpress_waf" {
  provider = aws.us_east_1
  name  = var.waf_name
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regla 1: Restricción geográfica - Solo Perú
  rule {
    name     = "GeoRestrictionRule"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["PE"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoRestrictionRule"
      sampled_requests_enabled   = true
    }
  }

  # Regla 2: Rate Limiting
  rule {
    name     = "RateLimitRule"
    priority = 5

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Regla 3: AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWS-ManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommonRulesMetric"
      sampled_requests_enabled   = true
    }
  }

  #Regla 4 log4shellProtection
  rule {
  name     = "AWSManagedRulesKnownBadInputsRule"
  priority = 10

  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    sampled_requests_enabled = true
    cloudwatch_metrics_enabled = true
    metric_name = "log4shellProtection"
  }
}

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "reyGasExpressWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Environment = var.environment
    Application = "reyGasExpress"
    ManagedBy   = "Terraform"
  }
}