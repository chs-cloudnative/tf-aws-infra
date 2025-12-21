# =================================================================================
# Module: dns/outputs
# =================================================================================
# Purpose: Output values for use by other modules
# =================================================================================

output "route53_record_fqdn" {
  description = "FQDN of the Route53 record"
  value       = aws_route53_record.app.fqdn
}

output "route53_record_name" {
  description = "Name of the Route53 record"
  value       = aws_route53_record.app.name
}

output "hosted_zone_id" {
  description = "Hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}
