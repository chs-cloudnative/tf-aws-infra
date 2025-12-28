# =================================================================================
# Module: dns/root/outputs
# =================================================================================
# Purpose: Output values for Root DNS resources
# =================================================================================

output "root_zone_id" {
  description = "Root Hosted Zone ID"
  value       = aws_route53_zone.root.zone_id
}

output "root_name_servers" {
  description = "Root Zone Name Servers (Update in Namecheap!)"
  value       = aws_route53_zone.root.name_servers
}

output "dev_delegation_record_name" {
  description = "Dev delegation NS record name"
  value       = aws_route53_record.dev_delegation.name
}

output "dev_delegation_name_servers" {
  description = "Dev delegation NS values (auto-synced from Dev Zone)"
  value       = aws_route53_record.dev_delegation.records
}