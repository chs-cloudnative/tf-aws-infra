# =================================================================================
# Module: dns/root/route53
# =================================================================================
# Purpose: 
#   Root Hosted Zone and subdomain delegation management
#
# Components:
#   1. Root Hosted Zone (chs4150.me)
#   2. NS delegation record for dev subdomain
#
# Architecture:
#   Namecheap → Root Zone → Dev Zone (via NS delegation)
#
# Cross-Account Design:
#   - Root Zone created in Root Account
#   - Dev Zone Name Servers passed as variable (from Dev Account)
#   - No data source needed (avoids cross-account query)
#
# Post-deployment:
#   - Update Namecheap with Root Zone Name Servers (one-time)
#   - Dev delegation updates automatically when Dev NS changes
# =================================================================================

# ---------------------------------------------------------------------------------
# Root Hosted Zone
# ---------------------------------------------------------------------------------

resource "aws_route53_zone" "root" {
  name = var.root_domain

  tags = {
    Name        = "${var.root_domain}-root-zone"
    Environment = "shared"
    ManagedBy   = "terraform"
    Purpose     = "RootDNS"
  }
}

# ---------------------------------------------------------------------------------
# Dev Subdomain Delegation (NS Record)
# ---------------------------------------------------------------------------------
# Points to Dev Hosted Zone Name Servers (in Dev Account)

resource "aws_route53_record" "dev_delegation" {
  zone_id = aws_route53_zone.root.zone_id
  name    = var.dev_domain
  type    = "NS"
  ttl     = 300
  records = var.dev_name_servers
}
