# =================================================================================
# Module: dns/route53
# =================================================================================
# Purpose: 
#   Route53 DNS record pointing to Application Load Balancer
#
# Configuration:
#   - A record (IPv4)
#   - Alias record (points to ALB)
#   - Health check evaluation enabled
#
# DNS Flow:
#   User → dev.chs4150.me → Route53 → ALB → Target Group → EC2 Instances
#
# Benefits:
#   - No IP address management (ALB IP can change)
#   - Automatic failover if ALB is unhealthy
#   - No charge for alias queries
#
# Notes:
#   - Hosted zone must exist (created manually or in root account)
#   - This creates only the A record within the existing zone
#   - evaluate_target_health ensures traffic doesn't route to unhealthy ALB
# =================================================================================

# ---------------------------------------------------------------------------------
# Data Source: Existing Hosted Zone
# ---------------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ---------------------------------------------------------------------------------
# A Record (Alias to ALB)
# ---------------------------------------------------------------------------------

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.load_balancer_dns_name
    zone_id                = var.load_balancer_zone_id
    evaluate_target_health = true
  }
}
