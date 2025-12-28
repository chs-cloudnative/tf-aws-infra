# =================================================================================
# Module: dns/dev/variables
# =================================================================================
# Purpose: Input variables for Dev DNS module
# =================================================================================

variable "dev_domain" {
  type        = string
  description = "Dev domain name (e.g., dev.chs4150.me)"
}

variable "load_balancer_dns_name" {
  type        = string
  description = "Application Load Balancer DNS name"
}

variable "load_balancer_zone_id" {
  type        = string
  description = "Application Load Balancer hosted zone ID"
}
