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
# A Record: Point domain to EC2 instance
# -------------------------------------------------------------------

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [aws_instance.app.public_ip]
}