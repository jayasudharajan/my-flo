module "waf" {
  source = "umotif-public/waf-webaclv2/aws"
  version = "~> 3.0.1"

  name_prefix = var.name_prefix

  allow_default_action = true

  scope = "REGIONAL"

  alb_arn = lookup(data.external.alb_arn.result, "alb_arn")

  create_alb_association = true

  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.name_prefix}-waf-setup-waf-main-metrics"
    sampled_requests_enabled   = false
  }

  rules = [
    {
      ### AND rule example
      name     = "block-auth-uri-path-if-too-frequent"
      priority = 2
      action   = "block"

      rate_based_statement = {
        limit              = var.requests_per_ip_limit
        aggregate_key_type = "IP"

        # refine what gets rate limited
        scope_down_statement = {
            byte_match_statement = {
              field_to_match = {
                uri_path = "{}"
              }
              positional_constraint = "STARTS_WITH"
              search_string         = "/api/v1/oauth2"
              priority              = 0
              type                  = "NONE"
            }
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = false
        sampled_requests_enabled   = true
      }
    }
  ]

  tags = {
    "Environment" = var.environment
  }
}

data "external" "alb_arn" {
  program = ["bash", "${path.module}/resolve_alb_id.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    aws_profile = var.profile
    alb_pattern = "k8s-flopubli"
  }
}
