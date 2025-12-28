# =================================================================================
# Module: dns/dev/outputs
# =================================================================================
# Purpose: Output values for Dev DNS resources
# =================================================================================

output "dev_zone_id" {
  description = "Dev Hosted Zone ID"
  value       = aws_route53_zone.dev.zone_id
}

output "dev_zone_arn" {
  description = "Dev Hosted Zone ARN"
  value       = aws_route53_zone.dev.arn
}

output "dev_zone_name" {
  description = "Dev Hosted Zone name"
  value       = aws_route53_zone.dev.name
}

output "dev_name_servers" {
  description = "Dev Zone Name Servers (used by Root delegation)"
  value       = aws_route53_zone.dev.name_servers
}

output "dev_record_fqdn" {
  description = "Dev A record FQDN"
  value       = aws_route53_record.dev_app.fqdn
}

output "dev_record_name" {
  description = "Dev A record name"
  value       = aws_route53_record.dev_app.name
}
