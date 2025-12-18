# ===================================================================
# Route 53 Configuration
# ===================================================================

# -------------------------------------------------------------------
# Data Source: Get existing hosted zone
# -------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# -------------------------------------------------------------------
# A Record (Alias): Point domain to Load Balancer
# -------------------------------------------------------------------

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.webapp.dns_name
    zone_id                = aws_lb.webapp.zone_id
    evaluate_target_health = true
  }
}