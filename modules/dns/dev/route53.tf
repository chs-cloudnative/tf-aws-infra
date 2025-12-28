# =================================================================================
# Module: dns/dev/route53
# =================================================================================
# Purpose: 
#   Dev Hosted Zone and application DNS records management
#
# Components:
#   1. Dev Hosted Zone (dev.chs4150.me)
#   2. A Record - Alias pointing to Application Load Balancer
#
# Configuration:
#   - Hosted Zone for dev subdomain
#   - A record (IPv4 alias to ALB)
#   - Health check evaluation enabled
#
# DNS Flow:
#   User → dev.chs4150.me → Dev Zone → A record → ALB → EC2 Instances
#
# Important Notes:
#   - Hosted Zone managed by Terraform (created/destroyed automatically)
#   - terraform destroy will delete this Hosted Zone
#   - Name Servers may change when Hosted Zone is recreated
#   - Root Account NS delegation must point to these Name Servers
#
# Benefits:
#   - Full infrastructure automation
#   - No manual DNS setup required
#   - Automatic failover if ALB is unhealthy
#   - Zero cost when infrastructure is destroyed
# =================================================================================

# ---------------------------------------------------------------------------------
# Dev Hosted Zone
# ---------------------------------------------------------------------------------

resource "aws_route53_zone" "dev" {
  name = var.dev_domain

  tags = {
    Name        = "${var.dev_domain}-dev-zone"
    Environment = "dev"
    ManagedBy   = "terraform"
    Purpose     = "DevApplicationDNS"
  }
}

# ---------------------------------------------------------------------------------
# A Record (Alias to ALB)
# ---------------------------------------------------------------------------------

resource "aws_route53_record" "dev_app" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = var.dev_domain
  type    = "A"

  alias {
    name                   = var.load_balancer_dns_name
    zone_id                = var.load_balancer_zone_id
    evaluate_target_health = true
  }
}
